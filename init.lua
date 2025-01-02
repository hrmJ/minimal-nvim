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
