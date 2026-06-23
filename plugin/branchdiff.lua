local function branch_diff(opts)
	local branch = opts.args
	local files = vim.fn.systemlist("git diff --name-only " .. vim.fn.shellescape(branch) .. " -- .")
	if vim.v.shell_error ~= 0 or #files == 0 then
		vim.notify("No differences against " .. branch, vim.log.levels.INFO)
		return
	end

	vim.fn.setqflist({}, " ", {
		title = "BranchDiff: " .. branch,
		items = vim.tbl_map(function(f)
			return { filename = f, lnum = 1, text = "modified vs " .. branch }
		end, files),
	})
	vim.cmd("copen")

	local bufnr = vim.api.nvim_get_current_buf()
	local bopts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "d", function()
		local entry = vim.fn.getqflist()[vim.fn.line(".")]
		local file = vim.api.nvim_buf_get_name(entry.bufnr)
		if file == "" then
			return
		end
		local qf_win = vim.api.nvim_get_current_win()
		local qf_height = vim.api.nvim_win_get_height(qf_win)
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if win ~= qf_win then
				vim.api.nvim_win_close(win, false)
			end
		end
		vim.cmd("aboveleft split " .. vim.fn.fnameescape(file))
		vim.cmd("Gvdiffsplit " .. branch)
		vim.fn.win_gotoid(qf_win)
		vim.api.nvim_win_set_height(qf_win, qf_height)
	end, bopts)

	vim.keymap.set("n", "co", function()
		local idx = vim.fn.line(".")
		local qflist = vim.fn.getqflist()
		local file = vim.api.nvim_buf_get_name(qflist[idx].bufnr)
		if file == "" then
			return
		end
		vim.fn.system("git checkout " .. vim.fn.shellescape(branch) .. " -- " .. vim.fn.shellescape(file))
		table.remove(qflist, idx)
		vim.fn.setqflist(qflist, "r")
		vim.notify("Checked out: " .. vim.fn.fnamemodify(file, ":~:."))
	end, bopts)

	vim.keymap.set("v", "co", function()
		local start = vim.fn.line("v")
		local finish = vim.fn.line(".")
		if start > finish then
			start, finish = finish, start
		end
		local qflist = vim.fn.getqflist()
		local count = 0
		for i = finish, start, -1 do
			local file = vim.api.nvim_buf_get_name(qflist[i].bufnr)
			if file ~= "" then
				vim.fn.system("git checkout " .. vim.fn.shellescape(branch) .. " -- " .. vim.fn.shellescape(file))
				count = count + 1
			end
			table.remove(qflist, i)
		end
		vim.fn.setqflist(qflist, "r")
		vim.notify("Checked out " .. count .. " files")
	end, bopts)

	vim.keymap.set({ "n", "v" }, "dd", function()
		local start, finish
		if vim.fn.mode() == "n" then
			start, finish = vim.fn.line("."), vim.fn.line(".")
		else
			start, finish = vim.fn.line("v"), vim.fn.line(".")
			if start > finish then
				start, finish = finish, start
			end
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		end
		local qflist = vim.fn.getqflist()
		for i = finish, start, -1 do
			table.remove(qflist, i)
		end
		vim.fn.setqflist(qflist, "r")
	end, bopts)
end

vim.api.nvim_create_user_command("BranchDiff", branch_diff, {
	nargs = 1,
	complete = function()
		return vim.fn.systemlist("git branch --format='%(refname:short)' 2>/dev/null")
	end,
})
