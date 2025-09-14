return {
	{
		"rlane/pounce.nvim",
		lazy = false,
		config = function()
			require("pounce").setup()
			vim.keymap.set("n", "s", ":Pounce<CR>", { noremap = true, silent = true })
			vim.keymap.set("v", "s", ":Pounce<CR>", { noremap = true, silent = true })
		end,
	},
	-- { "tpope/vim-vinegar", lazy=false } ,
	{
		"stevearc/oil.nvim",
		opts = {},
		lazy = false,
		config = function()
			require("oil").setup({ view_options = {
				show_hidden = true,
			} })
			vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		end,
	},
}
