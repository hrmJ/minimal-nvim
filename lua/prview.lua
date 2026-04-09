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
	vim.keymap.set("n", "s", function()
		M.open_with_signs(buf)
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

function M.open_with_signs(buf)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_var(buf, "pr_lines")
	local line = lines[cursor[1]]
	if not line or not line.status then return end

	local clean_path = line.path:gsub("^/", "")
	local base_branch = "origin/develop"

	-- Close non-PR windows
	local pr_win = vim.api.nvim_get_current_win()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if win ~= pr_win then pcall(vim.api.nvim_win_close, win, false) end
	end

	-- Open file in a split
	vim.api.nvim_set_current_win(pr_win)
	vim.cmd("rightbelow vsplit")
	vim.cmd("edit " .. vim.fn.fnameescape(clean_path))
	vim.api.nvim_win_set_width(pr_win, math.floor(vim.o.columns * 0.3))

	local file_buf = vim.api.nvim_get_current_buf()
	local ns = vim.api.nvim_create_namespace("prview_diffsigns")
	vim.api.nvim_buf_clear_namespace(file_buf, ns, 0, -1)

	-- Get diff hunks from git
	local cmd = string.format("git diff -U0 %s -- %s", base_branch, clean_path)
	local diff = vim.fn.systemlist(cmd)

	local hunk_starts = {}
	for _, l in ipairs(diff) do
		local new_start, new_count = l:match("^@@ %-[%d,]+ %+(%d+),?(%d*) @@")
		if new_start then
			new_start = tonumber(new_start)
			new_count = tonumber(new_count ~= "" and new_count or "1")
			if new_count == 0 then
				local at = math.max(new_start, 1)
				table.insert(hunk_starts, at)
				pcall(vim.api.nvim_buf_set_extmark, file_buf, ns, at - 1, 0, {
					sign_text = "▁", sign_hl_group = "DiffDelete",
				})
			else
				table.insert(hunk_starts, new_start)
				for i = new_start, new_start + new_count - 1 do
					pcall(vim.api.nvim_buf_set_extmark, file_buf, ns, i - 1, 0, {
						sign_text = "▎", sign_hl_group = "DiffAdd",
					})
				end
			end
		end
	end

	table.sort(hunk_starts)
	vim.b[file_buf].prview_hunks = hunk_starts
	vim.b[file_buf].prview_path = clean_path
	vim.b[file_buf].prview_base = base_branch

	vim.keymap.set("n", "]h", function()
		local hunks = vim.b.prview_hunks or {}
		local cur = vim.api.nvim_win_get_cursor(0)[1]
		for _, lnum in ipairs(hunks) do
			if lnum > cur then
				vim.api.nvim_win_set_cursor(0, { lnum, 0 })
				return
			end
		end
		vim.notify("No next hunk", vim.log.levels.INFO)
	end, { buffer = file_buf })

	vim.keymap.set("n", "[h", function()
		local hunks = vim.b.prview_hunks or {}
		local cur = vim.api.nvim_win_get_cursor(0)[1]
		for i = #hunks, 1, -1 do
			if hunks[i] < cur then
				vim.api.nvim_win_set_cursor(0, { hunks[i], 0 })
				return
			end
		end
		vim.notify("No previous hunk", vim.log.levels.INFO)
	end, { buffer = file_buf })

	vim.keymap.set("n", "<leader>dp", function()
		local fpath = vim.b.prview_path
		local bbase = vim.b.prview_base
		if not fpath then return end

		local cur = vim.api.nvim_win_get_cursor(0)[1]
		local diff_out = vim.fn.systemlist(string.format("git diff -U0 %s -- %s", bbase, fpath))
		if #diff_out == 0 then return vim.notify("No diff", vim.log.levels.INFO) end

		-- Parse hunks: collect removed/added lines per hunk
		local hunks = {}
		local current
		for _, l in ipairs(diff_out) do
			local ns_val, nc = l:match("^@@ %-[%d,]+ %+(%d+),?(%d*) @@")
			if ns_val then
				current = {
					start = tonumber(ns_val),
					count = tonumber(nc ~= "" and nc or "1"),
					removed = {},
					added = {},
				}
				current.fin = current.start + current.count - 1
				table.insert(hunks, current)
			elseif current then
				if l:match("^%-") then
					table.insert(current.removed, l)
				elseif l:match("^%+") then
					table.insert(current.added, l)
				end
			end
		end

		-- Find hunk nearest to cursor
		local best, best_dist = hunks[1], math.huge
		for _, h in ipairs(hunks) do
			local dist = (cur >= h.start and cur <= h.fin) and 0
				or math.min(math.abs(cur - h.start), math.abs(cur - h.fin))
			if dist < best_dist then best_dist, best = dist, h end
		end
		if not best then return end

		-- Build display lines: removed then added, like gitsigns
		local preview_lines = {}
		local hls = {}
		for _, r in ipairs(best.removed) do
			table.insert(preview_lines, r)
			table.insert(hls, "GitSignsDeletePreview")
		end
		for _, a in ipairs(best.added) do
			table.insert(preview_lines, a)
			table.insert(hls, "GitSignsAddPreview")
		end
		if #preview_lines == 0 then return end

		local fbuf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, preview_lines)
		vim.bo[fbuf].bufhidden = "wipe"

		-- Apply line highlights
		local hl_ns = vim.api.nvim_create_namespace("prview_preview")
		for i, hl in ipairs(hls) do
			vim.api.nvim_buf_set_extmark(fbuf, hl_ns, i - 1, 0, {
				hl_group = hl, hl_eol = true, end_row = i,
			})
		end

		-- Size to content
		local width = 0
		for _, l in ipairs(preview_lines) do
			width = math.max(width, vim.fn.strdisplaywidth(l) + 1)
		end
		width = math.min(width, math.floor(vim.o.columns * 0.8))
		local height = math.min(#preview_lines, math.floor(vim.o.lines * 0.5))

		local float_win = vim.api.nvim_open_win(fbuf, false, {
			relative = "cursor", row = 1, col = 0,
			width = width, height = height,
			style = "minimal", border = "rounded",
		})
		vim.wo[float_win].signcolumn = "no"

		-- Auto-close on cursor move
		local old_cursor = vim.api.nvim_win_get_cursor(0)
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = file_buf,
			once = true,
			callback = function()
				pcall(vim.api.nvim_win_close, float_win, true)
			end,
		})
		vim.keymap.set("n", "q", function()
			pcall(vim.api.nvim_win_close, float_win, true)
		end, { buffer = file_buf })
	end, { buffer = file_buf })

	vim.keymap.set("n", "<leader>ds", function()
		local fpath = vim.b.prview_path
		local bbase = vim.b.prview_base
		if not fpath then return end

		local cur = vim.api.nvim_win_get_cursor(0)[1]
		local diff_out = vim.fn.systemlist(string.format("git diff -U0 %s -- %s", bbase, fpath))
		if #diff_out == 0 then return vim.notify("No diff", vim.log.levels.INFO) end

		-- Parse hunks
		local hunks = {}
		local current
		for _, l in ipairs(diff_out) do
			local os, oc, ns_val, nc = l:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
			if os then
				current = {
					old_start = tonumber(os),
					old_count = tonumber(oc ~= "" and oc or "1"),
					new_start = tonumber(ns_val),
					new_count = tonumber(nc ~= "" and nc or "1"),
					removed = {}, added = {},
				}
				table.insert(hunks, current)
			elseif current then
				if l:match("^%-") then table.insert(current.removed, l:sub(2))
				elseif l:match("^%+") then table.insert(current.added, l:sub(2)) end
			end
		end

		-- Find nearest hunk
		local best, best_dist = hunks[1], math.huge
		for _, h in ipairs(hunks) do
			local fin = h.new_start + h.new_count - 1
			local dist = (cur >= h.new_start and cur <= fin) and 0
				or math.min(math.abs(cur - h.new_start), math.abs(cur - fin))
			if dist < best_dist then best_dist, best = dist, h end
		end
		if not best then return end

		-- Add context: grab surrounding lines from both versions
		local ctx = 3
		local old_lines = vim.fn.systemlist(string.format("git show %s:%s", bbase, fpath))
		local new_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		local old_from = math.max(1, best.old_start - ctx)
		local old_to = math.min(#old_lines, best.old_start + best.old_count - 1 + ctx)
		local new_from = math.max(1, best.new_start - ctx)
		local new_to = math.min(#new_lines, best.new_start + best.new_count - 1 + ctx)

		local left = {}
		for i = old_from, old_to do left[#left + 1] = old_lines[i] or "" end
		local right = {}
		for i = new_from, new_to do right[#right + 1] = new_lines[i] or "" end

		-- Pad to equal height
		local height = math.max(#left, #right)
		while #left < height do left[#left + 1] = "" end
		while #right < height do right[#right + 1] = "" end

		-- Create two buffers
		local ft = vim.bo[file_buf].filetype
		local lbuf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(lbuf, 0, -1, false, left)
		vim.bo[lbuf].filetype = ft
		vim.bo[lbuf].bufhidden = "wipe"

		local rbuf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(rbuf, 0, -1, false, right)
		vim.bo[rbuf].filetype = ft
		vim.bo[rbuf].bufhidden = "wipe"

		-- Highlight changed lines
		local hl_ns_l = vim.api.nvim_create_namespace("prview_split_l")
		local hl_ns_r = vim.api.nvim_create_namespace("prview_split_r")
		for i = ctx + 1, ctx + best.old_count do
			pcall(vim.api.nvim_buf_set_extmark, lbuf, hl_ns_l, i - 1, 0, {
				hl_group = "DiffDelete", hl_eol = true, end_row = i,
			})
		end
		for i = ctx + 1, ctx + best.new_count do
			pcall(vim.api.nvim_buf_set_extmark, rbuf, hl_ns_r, i - 1, 0, {
				hl_group = "DiffAdd", hl_eol = true, end_row = i,
			})
		end

		-- Window dimensions
		local total_w = math.floor(vim.o.columns * 0.8)
		local pane_w = math.floor((total_w - 3) / 2) -- 3 for separator + borders
		local win_h = math.min(height, math.floor(vim.o.lines * 0.5))
		local row = math.floor((vim.o.lines - win_h) / 2)
		local col = math.floor((vim.o.columns - total_w) / 2)

		local lwin = vim.api.nvim_open_win(lbuf, false, {
			relative = "editor", row = row, col = col,
			width = pane_w, height = win_h,
			style = "minimal", border = "rounded",
			title = " " .. bbase .. " ", title_pos = "center",
		})

		local rwin = vim.api.nvim_open_win(rbuf, false, {
			relative = "editor", row = row, col = col + pane_w + 1,
			width = pane_w, height = win_h,
			style = "minimal", border = "rounded",
			title = " current ", title_pos = "center",
		})

		-- Close both on cursor move or q
		local function close_both()
			pcall(vim.api.nvim_win_close, lwin, true)
			pcall(vim.api.nvim_win_close, rwin, true)
		end
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = file_buf, once = true, callback = close_both,
		})
		vim.keymap.set("n", "q", close_both, { buffer = file_buf })
	end, { buffer = file_buf })
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
