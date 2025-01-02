return {
	{
		"nvim-treesitter/nvim-treesitter",
    event = "BufRead", -- Load only when reading a file
		run = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "lua", "python", "javascript", "typescript", "tsx" }, -- Adjust based on your languages
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true, -- Enable automatic indentation
				},
			})
		end,
	},
	{
		"catppuccin/nvim",
    event = "BufRead", -- Load only when reading a file
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
}
