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
}
