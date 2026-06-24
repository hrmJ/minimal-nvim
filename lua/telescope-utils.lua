local M = {}

local function open_in_tmux(prompt_bufnr, split_flag)
	local action_state = require("telescope.actions.state")
	local actions = require("telescope.actions")
	local entry = action_state.get_selected_entry()

	local filepath
	if entry.bufnr then
		filepath = vim.api.nvim_buf_get_name(entry.bufnr)
	elseif entry.path then
		filepath = entry.path
	elseif entry.filename then
		filepath = entry.filename
	end

	if not filepath or filepath == "" then
		return
	end

	actions.close(prompt_bufnr)

	local dir = vim.fs.dirname(filepath)
	local pkg = vim.fs.find("package.json", { path = dir, upward = true })[1]
	local cwd = pkg and vim.fs.dirname(pkg) or dir
	local pane_name = vim.fn.fnamemodify(cwd, ":t")

	vim.fn.system({ "tmux", "split-window", split_flag, "-c", cwd, "nvim", filepath })
	vim.fn.system({ "tmux", "select-pane", "-T", pane_name })

	if entry.bufnr then
		vim.api.nvim_buf_delete(entry.bufnr, { force = true })
	end
end

function M.open_in_tmux_pane(prompt_bufnr)
	open_in_tmux(prompt_bufnr, "-h")
end

function M.open_in_tmux_win(prompt_bufnr)
	local action_state = require("telescope.actions.state")
	local actions = require("telescope.actions")
	local entry = action_state.get_selected_entry()

	local filepath
	if entry.bufnr then
		filepath = vim.api.nvim_buf_get_name(entry.bufnr)
	elseif entry.path then
		filepath = entry.path
	elseif entry.filename then
		filepath = entry.filename
	end

	if not filepath or filepath == "" then
		return
	end

	actions.close(prompt_bufnr)

	local dir = vim.fs.dirname(filepath)
	local pkg = vim.fs.find("package.json", { path = dir, upward = true })[1]
	local cwd = pkg and vim.fs.dirname(pkg) or dir
	local win_name = vim.fn.fnamemodify(cwd, ":t")

	vim.fn.system({ "tmux", "new-window", "-n", win_name, "-c", cwd, "nvim", filepath })

	if entry.bufnr then
		vim.api.nvim_buf_delete(entry.bufnr, { force = true })
	end
end

function M.open_in_tmux_pane_vertical(prompt_bufnr)
	open_in_tmux(prompt_bufnr, "-v")
end

function M.path_display(_, path)
	local max_len = 50
	if #path <= max_len then
		return path
	end
	local parts = vim.split(path, "/")
	if #parts <= 2 then
		return path
	end
	local filename = parts[#parts]
	local start_parts = { parts[1] }
	if #parts > 2 then
		table.insert(start_parts, parts[2])
	end
	local start = table.concat(start_parts, "/")
	return start .. "/...../" .. filename
end

return M
