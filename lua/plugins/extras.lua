return {
	{
		"Olical/vim-enmasse",
		version = "*",
		lazy = false,
	},
	{
		"echasnovski/mini.nvim",
		version = "*",
		lazy = false,
		config = function()
			local starter = require("mini.starter")
			local MiniPick = require("mini.pick")
			-- require("mini.starter").setup({
			-- 	items = {
			-- 		starter.sections.recent_files(9, true, true),
			-- 		starter.sections.recent_files(11, false, true),
			-- 		starter.sections.pick,
			-- 	},
			-- })
			--
			-- local wipeout_cur = function()
			-- 	vim.api.nvim_buf_delete(MiniPick.get_picker_matches().current.bufnr, {})
			-- end
			-- local buffer_mappings = { wipeout = { char = "<C-d>", func = wipeout_cur } }
			--
			-- vim.keymap.set("n", "<leader>mb", function()
			-- 	MiniPick.builtin.buffers({}, { mappings = buffer_mappings })
			-- end, { noremap = true, silent = true })
			--
			-- require("mini.pick").setup({})
			-- require("mini.extra").setup()
			require("mini.indentscope").setup()
			-- require("mini.surround").setup({
			-- 	mappings = {
			-- 		add = "ys", -- Add surrounding in Normal and Visual modes
			-- 		delete = "ds", -- Delete surrounding
			-- 		find = "", -- Find surrounding (to the right)
			-- 		find_left = "", -- Find surrounding (to the left)
			-- 		highlight = "", -- Highlight surrounding
			-- 		replace = "cs", -- Replace surrounding
			--
			-- 		update_n_lines = "yss", -- Update `n_lines`
			--
			-- 		suffix_last = "l", -- Suffix to search with "prev" method
			-- 		suffix_next = "n", -- Suffix to search with "next" method
			-- 	},
			-- })

			vim.api.nvim_set_keymap("n", "<leader>p", ":Pick ", { noremap = true, silent = true })
		end,
	},
	{
		"stevearc/aerial.nvim",
		lazy = false,
		opts = {},
		-- Optional dependencies
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("aerial").setup({
				-- optionally use on_attach to set keymaps when aerial has attached to a buffer
				on_attach = function(bufnr)
					-- Jump forwards/backwards with '{' and '}'
					vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
					vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
				end,
			})
			-- You probably also want to set a keymap to toggle aerial
			vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")
		end,
	},
}
