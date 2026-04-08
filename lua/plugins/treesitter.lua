return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		priority = 2000,
		run = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				ensure_installed = { "lua", "python", "javascript", "typescript", "tsx" },

				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "vn",
						node_incremental = "H",
						node_decremental = "L",
					},
				},

				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
			})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha
			require("catppuccin").setup()
			vim.api.nvim_command("colorscheme catppuccin")
			vim.cmd("hi! link DiagnosticHint String")
			vim.cmd("hi DiagnosticUnderlineError gui=undercurl")
			vim.cmd("hi DiagnosticUnderlineWarn  gui=undercurl")
			vim.cmd("hi DiagnosticUnderlineInfo  gui=undercurl")
			vim.cmd("hi DiagnosticUnderlineHint  gui=undercurl")
		end,
	},
	-- {
	-- 	"catppuccin/nvim",
	-- 	event = "BufRead", -- Load only when reading a file
	-- 	priority = 1000,
	-- config = function()
	-- 	vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha
	-- 	require("catppuccin").setup()
	-- 	vim.api.nvim_command("colorscheme catppuccin")
	--
	-- 	vim.cmd("hi! link DiagnosticHint String")
	-- 	vim.cmd("hi DiagnosticUnderlineError gui=undercurl")
	-- 	vim.cmd("hi DiagnosticUnderlineWarn  gui=undercurl")
	-- 	vim.cmd("hi DiagnosticUnderlineInfo  gui=undercurl")
	-- 	vim.cmd("hi DiagnosticUnderlineHint  gui=undercurl")
	-- end,
	-- },
}
