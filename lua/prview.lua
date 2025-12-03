local git_utils = require("prview_git")
local M = {}

-- Get list of changed files with their status from git diff
function M.get_changed_files(base_branch)
	base_branch = base_branch or "origin/develop"

	local cmd = string.format("git diff %s --name-status", base_branch)
	local handle = io.popen(cmd)
	if not handle then
		return nil, "Failed to run git command"
	end

	local result = handle:read("*a")
	handle:close()

	local files = {}
	for line in result:gmatch("[^\r\n]+") do
		if line ~= "" then
			local status, rest = line:match("^(%S+)%s+(.+)$")
			if status and rest then
				-- Handle renames (R100 old_path\tnew_path) - use only the new path
				local filepath = rest
				if status:match("^R") then
					-- For renames, take the second path (after tab)
					local paths = vim.split(rest, "\t")
					filepath = paths[#paths]
				end
				table.insert(files, { path = filepath, status = status })
			end
		end
	end

	return files
end

-- Parse file list into a tree structure
function M.build_tree(files)
	local tree = {}

	for _, file_obj in ipairs(files) do
		local parts = vim.split(file_obj.path, "/")
		local current = tree

		for i, part in ipairs(parts) do
			local is_file = (i == #parts)

			if not current[part] then
				current[part] = {
					name = part,
					is_file = is_file,
					status = is_file and file_obj.status or nil,
					children = is_file and nil or {},
				}
			end

			if not is_file then
				current = current[part].children
			end
		end
	end

	return tree
end

-- State to track expanded folders
M.expanded = {}
M.reviewed = {}

local function all_files_reviewed(node, path)
	local all_reviewed = true
	local has_files = false

	for key, item in pairs(node) do
		local item_path = path .. "/" .. item.name

		if item.is_file then
			has_files = true
			if not M.reviewed[item_path] then
				all_reviewed = false
			end
		elseif item.children then
			local sub_all, sub_has = all_files_reviewed(item.children, item_path)
			if sub_has then
				has_files = true
				if not sub_all then
					all_reviewed = false
				end
			end
		end
	end

	return all_reviewed, has_files
end

-- Collapse single-child folder chains
local function collapse_chain(node, name)
	local chain = { name }
	local current = node

	while current.children do
		local keys = vim.tbl_keys(current.children)
		-- Stop if we have files at this level or multiple children
		if #keys ~= 1 or current.children[keys[1]].is_file then
			break
		end

		local child_key = keys[1]
		table.insert(chain, child_key)
		current = current.children[child_key]
	end

	return table.concat(chain, "/"), current
end

-- Render tree to lines
local function render_node(node, lines, indent, path)
	local keys = vim.tbl_keys(node)
	table.sort(keys)

	for _, key in ipairs(keys) do
		local item = node[key]

		if item.is_file then
			local icon = "M" -- Modified
			if item.status == "A" then
				icon = "A" -- Added
			elseif item.status == "D" then
				icon = "D" -- Deleted
			end
			local checkbox = M.reviewed[path .. "/" .. item.name] and "[✓]" or "[ ]"
			local magnitude = git_utils.get_change_magnitude(path .. "/" .. item.name)
			local mag_display = magnitude ~= "" and " " .. magnitude or ""
			table.insert(lines, {
				text = string.rep("  ", indent) .. "  " .. checkbox .. " " .. icon .. " " .. item.name .. mag_display,
				path = path .. "/" .. item.name,
				status = item.status,
			})
		else
			local display_name, collapsed_node = collapse_chain(item, item.name)
			local full_path = path .. "/" .. display_name
			local is_expanded = M.expanded[full_path]

			-- Check if all files in this folder are reviewed
			local all_reviewed, has_files = all_files_reviewed(collapsed_node.children or {}, full_path)
			local checkbox = (has_files and all_reviewed) and "✓  " or "   "

			table.insert(lines, {
				text = string.rep("  ", indent) .. checkbox .. "  " .. display_name,
				path = full_path,
				is_folder = true,
				all_files_reviewed = all_reviewed and has_files,
			})

			if is_expanded and collapsed_node.children then
				render_node(collapsed_node.children, lines, indent + 1, full_path)
			end
		end
	end
end

function M.render_tree(tree)
	local lines = {}
	render_node(tree, lines, 0, "")
	return lines
end

-- Open PR review window
function M.open()
	local files = M.get_changed_files()
	if not files or #files == 0 then
		vim.notify("No changed files found", vim.log.levels.WARN)
		return
	end

	local tree = M.build_tree(files)

	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Set up highlighting
	vim.api.nvim_buf_set_option(buf, "syntax", "on")
	vim.cmd([[
    syntax match PRFolder /\v^\s*\zs/
    highlight default link PRFolder Directory
    highlight PRDeleted guifg=#E57373 ctermfg=167
    highlight PRTestFile guifg=#666666 ctermfg=242
    highlight PRReviewed guifg=#888888 ctermfg=244
  ]])

	-- Create window
	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_win_set_width(win, 30)

	-- Store tree in buffer variable
	vim.api.nvim_buf_set_var(buf, "pr_tree", tree)

	-- Render initial tree
	M.refresh_buffer(buf)

	-- Set up keymaps
	vim.keymap.set("n", "<CR>", function()
		M.toggle_folder(buf)
	end, { buffer = buf })
	vim.keymap.set("n", "d", function()
		M.open_diff(buf, false)
	end, { buffer = buf })
	vim.keymap.set("n", "D", function()
		M.open_diff(buf, true)
	end, { buffer = buf })
	vim.keymap.set("n", "v", function()
		M.open_vdiff(buf)
	end, { buffer = buf })
	vim.keymap.set("n", "p", function()
		M.preview_diff(buf)
	end, { buffer = buf })
	vim.keymap.set("n", "r", function()
		M.toggle_reviewed(buf)
	end, { buffer = buf })
	vim.keymap.set("n", "q", "<cmd>q<cr>", { buffer = buf })
end

function M.refresh_buffer(buf)
	local tree = vim.api.nvim_buf_get_var(buf, "pr_tree")
	local lines = M.render_tree(tree)

	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	local text_lines = vim.tbl_map(function(l)
		return l.text
	end, lines)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Store line metadata
	vim.api.nvim_buf_set_var(buf, "pr_lines", lines)

	-- Apply highlighting
	local ns_id = vim.api.nvim_create_namespace("prview_colors")
	vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

	for i, line in ipairs(lines) do
		local should_highlight_reviewed = M.reviewed[line.path]

		-- For folders, check if all files are reviewed
		if line.is_folder and not should_highlight_reviewed then
			should_highlight_reviewed = line.all_files_reviewed
		end

		-- Check if reviewed (for both files and folders)
		if should_highlight_reviewed then
			vim.api.nvim_buf_add_highlight(buf, ns_id, "PRReviewed", i - 1, 0, -1)
		elseif line.status then
			-- Highlight deleted files in salmon red
			if line.status == "D" then
				vim.api.nvim_buf_add_highlight(buf, ns_id, "PRDeleted", i - 1, 0, -1)
			-- Highlight test files in dark grey
			elseif line.path and (line.path:match("%.test%.ts$") or line.path:match("%.test%.tsx$")) then
				vim.api.nvim_buf_add_highlight(buf, ns_id, "PRTestFile", i - 1, 0, -1)
			end
		end
	end
end

function M.toggle_folder(buf)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_idx = cursor[1]

	local lines = vim.api.nvim_buf_get_var(buf, "pr_lines")
	local line = lines[line_idx]

	if line and line.is_folder then
		M.expanded[line.path] = not M.expanded[line.path]
		M.refresh_buffer(buf)
	elseif line and line.status then
		-- It's a file, close all non-PR windows and open it
		local pr_win = vim.api.nvim_get_current_win()
		local windows_to_close = {}
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if win ~= pr_win then
				table.insert(windows_to_close, win)
			end
		end

		for _, win in ipairs(windows_to_close) do
			pcall(vim.api.nvim_win_close, win, false)
		end

		vim.api.nvim_set_current_win(pr_win)
		vim.cmd("rightbelow vsplit")
		M.open_file(line.path)
	end
end

function M.open_file(filepath)
	-- Remove leading slash
	local clean_path = filepath:gsub("^/", "")

	-- Find a non-PR window to open the file in
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ok, _ = pcall(vim.api.nvim_buf_get_var, buf, "pr_tree")
		if not ok then
			-- This is not the PR window, use it
			vim.api.nvim_set_current_win(win)
			vim.cmd("edit " .. vim.fn.fnameescape(clean_path))
			return
		end
	end

	-- If no other window exists, create a new split
	vim.cmd("wincmd l")
	vim.cmd("edit " .. vim.fn.fnameescape(clean_path))
end

function M.open_diff(buf, use_side)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_idx = cursor[1]

	local lines = vim.api.nvim_buf_get_var(buf, "pr_lines")
	local line = lines[line_idx]

	if line and line.status then
		-- It's a file, open diff in browser
		local clean_path = line.path:gsub("^/", "")
		local base_branch = "origin/develop"
		-- local cmd = string.format("diff2html -- %s -- %s", base_branch, vim.fn.shellescape(clean_path))
		local cmd = string.format("diff2html -- %s -- %s", base_branch, vim.fn.shellescape(clean_path))
		local cmd_side =
			string.format("diff2html --style side -- %s  -- %s", base_branch, vim.fn.shellescape(clean_path))
		if use_side then
			vim.fn.jobstart(cmd_side, { detach = true })
		else
			vim.fn.jobstart(cmd, { detach = true })
		end
		vim.notify("Opening diff in browser...", vim.log.levels.INFO)
	end
end

function M.open_vdiff(buf)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_idx = cursor[1]

	local lines = vim.api.nvim_buf_get_var(buf, "pr_lines")
	local line = lines[line_idx]

	if line and line.status then
		-- It's a file, open in vertical diff split
		local clean_path = line.path:gsub("^/", "")

		-- Get list of windows to close (all except PR tree)
		local pr_win = vim.api.nvim_get_current_win()
		local windows_to_close = {}
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if win ~= pr_win then
				table.insert(windows_to_close, win)
			end
		end

		-- Close those windows
		for _, win in ipairs(windows_to_close) do
			pcall(vim.api.nvim_win_close, win, false)
		end

		-- Make sure we're still in the PR window, then create split to the right
		vim.api.nvim_set_current_win(pr_win)
		vim.cmd("rightbelow vsplit")
		vim.cmd("edit " .. vim.fn.fnameescape(clean_path))
		vim.cmd("Gvdiffsplit develop")
		-- vim.api.nvim_win_set_width(pr_win, 30)
	end
end

function M.preview_diff(buf)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_idx = cursor[1]

	local lines = vim.api.nvim_buf_get_var(buf, "pr_lines")
	local line = lines[line_idx]

	if line and line.status then
		local clean_path = line.path:gsub("^/", "")
		local base_branch = "origin/develop"

		-- Get the diff
		local cmd = string.format("git diff %s -- %s", base_branch, vim.fn.shellescape(clean_path))
		local handle = io.popen(cmd)
		if not handle then
			vim.notify("Failed to get diff", vim.log.levels.ERROR)
			return
		end

		local diff_output = handle:read("*a")
		handle:close()

		if diff_output == "" then
			vim.notify("No diff available", vim.log.levels.WARN)
			return
		end

		-- Split into lines
		local diff_lines = vim.split(diff_output, "\n")

		-- Create floating window positioned relative to cursor
		local width = math.floor(vim.o.columns * 0.6)
		local height = math.min(#diff_lines + 2, math.floor(vim.o.lines * 0.7))

		local float_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, diff_lines)
		vim.api.nvim_buf_set_option(float_buf, "filetype", "diff")
		vim.api.nvim_buf_set_option(float_buf, "modifiable", false)

		local float_win = vim.api.nvim_open_win(float_buf, false, {
			relative = "cursor",
			width = width,
			height = height,
			row = 1,
			col = 0,
			style = "minimal",
			border = "rounded",
		})

		-- Auto-close on cursor move
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = buf,
			once = true,
			callback = function()
				if vim.api.nvim_win_is_valid(float_win) then
					vim.api.nvim_win_close(float_win, true)
				end
			end,
		})
	end
end

function M.toggle_reviewed(buf)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_idx = cursor[1]

	local lines = vim.api.nvim_buf_get_var(buf, "pr_lines")
	local line = lines[line_idx]

	if line and (line.status or line.is_folder) then
		M.reviewed[line.path] = not M.reviewed[line.path]
		M.refresh_buffer(buf)
	end
end

return M
