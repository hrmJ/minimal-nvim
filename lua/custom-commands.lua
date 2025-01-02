local function diagnose_quickfix_files()
	local qf_list = vim.fn.getqflist()
	for _, item in ipairs(qf_list) do
		-- Ensure the file is associated with a valid buffer
		local bufnr = item.bufnr
		if bufnr and bufnr > 0 then
			-- Load the buffer if it's not already loaded
			if not vim.api.nvim_buf_is_loaded(bufnr) then
				vim.fn.bufload(bufnr)
			end
			-- Open the file to attach LSP (if not already attached)
			vim.api.nvim_buf_call(bufnr, function()
				vim.cmd("edit " .. vim.api.nvim_buf_get_name(bufnr))
			end)
		end
	end
	print("Loaded and attached LSP to all files in quickfix list.")
end

vim.api.nvim_create_user_command("DiagnoseQuickfix", diagnose_quickfix_files, {})
