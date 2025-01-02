return {
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
		config = function()
			require("fzf-lua").setup({
				profile = "telescope",
				keymap = {
					builtin = {
						["<Esc>"] = "<C-\\><C-n>",
					},
				},
			})
			-- vim.keymap.set("n", "<C-p>", require("fzf-lua").files, { desc = "FZF [L]ist [F]iles", expr })
			vim.keymap.set("n", "<C-s>", "<cmd>lua require('fzf-lua').git_status({preview={layout='vertical'}})<cr>")
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "BufReadPost",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	{
		"kylechui/nvim-surround",
		event = "BufReadPost",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	},
	{
		"chentoast/marks.nvim",
		event = "BufReadPost",
		config = function()
			require("marks").setup()
		end,
	},
	{
		"numToStr/Comment.nvim",
		event = "BufReadPost",
		config = function()
			require("Comment").setup()
		end,
	},

	{ "tpope/vim-eunuch" },
}
