local M = {}

function M.format_snapshot()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getline(start_pos[2], end_pos[2])

	lines[#lines] = lines[#lines]:sub(1, end_pos[3])
	lines[1] = lines[1]:sub(start_pos[3])
	local expr = table.concat(lines, "\n")

	local bin = vim.g.snapshot_format_bin or "~/bin/as_snapshot_result"
	local result = vim.fn.system(bin, expr)
	if vim.v.shell_error ~= 0 then
		vim.notify("snapshot-format: " .. result, vim.log.levels.ERROR)
		return
	end

	-- single-line snapshots: `value`
	-- multi-line: `\n  indented\n`
	local snap_lines = vim.split(result, "\n")
	local replacement
	if #snap_lines == 1 then
		replacement = { "`" .. result .. "`" }
	else
		local base_indent = vim.fn.getline(start_pos[2]):match("^(%s*)")
		local inner_indent = base_indent .. "  "
		replacement = { "`" }
		for _, line in ipairs(snap_lines) do
			table.insert(replacement, inner_indent .. line)
		end
		table.insert(replacement, base_indent .. "`")
	end

	local text = table.concat(replacement, "\n")
	vim.fn.setreg("s", text)
	vim.cmd('normal! gv"sp')
end

vim.keymap.set("v", "<leader>v", ":<C-u>lua require('snapshot-format').format_snapshot()<CR>", { silent = true })

return M
