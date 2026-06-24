-- Ensure lazy.nvim is installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- General Neovim settings for the minimal config
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.syntax = "on"
vim.g.mapleader = "," -- Set the leader key to ','
vim.opt.wrap = false
vim.opt.expandtab = true
vim.opt.hidden = true
vim.o.termguicolors = true

-- Set autoindent, expandtab, and other indent-related options
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

-- Disable highlighting after search and ignore case when searching
vim.opt.hlsearch = false
vim.opt.ignorecase = true

-- Terminal mode keybinding for <A-o>
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		vim.api.nvim_buf_set_keymap(0, "t", "<A-o>", "<C-\\><C-n>", { noremap = true })
	end,
})

local key = vim.api.nvim_set_keymap
key("i", ",,", "<c-o>a", { noremap = true, silent = true })

-- Load plugins from the plugins.lua file
require("lazy").setup("plugins", {
	defaults = { lazy = true }, -- Lazy load plugins by default
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- Lockfile location
})

require("custom-commands")
require("scoped-search")

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		if vim.bo.filetype == "" and vim.fn.expand("%:e") ~= "" then
			vim.cmd("filetype detect")
		end
	end,
})

vim.keymap.set("n", "<leader>cr", ':let @+=expand("%")<CR>', { silent = true })
vim.keymap.set("n", "<leader>ct", ':let @+=expand("%:p")<CR>', { silent = true })

vim.api.nvim_create_user_command("Tsc", function(opts)
	local dir = opts.args ~= "" and opts.args or "."
	local output = vim.fn.system("cd " .. dir .. " && npx tsc --noEmit 2>&1")
	local items = {}
	for _, line in ipairs(vim.split(output, "\n")) do
		local file, lnum, col, msg = line:match("^(.+)%((%d+),(%d+)%):%s*(.+)$")
		if file then
			table.insert(items, { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = msg })
		end
	end
	vim.fn.setqflist(items, " ")
	vim.cmd.copen()
end, { nargs = "?", complete = "dir" })

local bb_pr_url = nil
vim.keymap.set("n", "<leader>B", function()
	local function open(pr_url)
		local file = vim.fn.expand("%:.")
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local encoded = file:gsub("/", "%%2F")
		local url = string.format("%s/diff#%s?t=%d", pr_url, encoded, line)
		vim.fn.system({ "open", url })
	end

	if bb_pr_url then
		open(bb_pr_url)
	else
		vim.ui.input({ prompt = "PR URL: " }, function(input)
			if not input or input == "" then
				return
			end
			bb_pr_url = input:gsub("/$", "")
			open(bb_pr_url)
		end)
	end
end, { desc = "Open Bitbucket PR diff at current line" })

vim.keymap.set("n", "<leader>pv", function()
	require("prview").open()
end, { desc = "Open PR review" })

vim.keymap.set("n", "<leader>ps", function()
	local file = vim.fn.expand("%:.")
	if file == "" then
		return
	end
	require("prview").activate_signs(vim.api.nvim_get_current_buf(), file)
end, { desc = "Activate PR diff signs on current file" })

vim.keymap.set("n", "<leader>G", "<cmd>ScopedSearch<cr>", { desc = "Scoped search in file's dir" })

require("snapshot-format")
vim.g.snapshot_format_bin = "~/.local/bin/as_snapshot_result"

-- Make all yanks and deletes go to system clipboard as well
vim.opt.clipboard = "unnamedplus"
