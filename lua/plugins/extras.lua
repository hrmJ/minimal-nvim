return {

	{
		"echasnovski/mini.nvim",
		version = "*",
		lazy = false,
		config = function()
			local starter = require("mini.starter")
			require("mini.starter").setup({
				items = {
					starter.sections.recent_files(9, true, true),
					starter.sections.recent_files(11, false, true),
					starter.sections.pick,
				},
			})

			require("mini.pick").setup()
			require("mini.extra").setup()
			require("mini.indentscope").setup()
			require("mini.surround").setup({
				mappings = {
					add = "ys", -- Add surrounding in Normal and Visual modes
					delete = "ds", -- Delete surrounding
					find = "", -- Find surrounding (to the right)
					find_left = "", -- Find surrounding (to the left)
					highlight = "", -- Highlight surrounding
					replace = "cs", -- Replace surrounding

					update_n_lines = "yss", -- Update `n_lines`

					suffix_last = "l", -- Suffix to search with "prev" method
					suffix_next = "n", -- Suffix to search with "next" method
				},
			})

			vim.api.nvim_set_keymap("n", "<leader>p", ":Pick ", { noremap = true, silent = true })
		end,
	},
}
