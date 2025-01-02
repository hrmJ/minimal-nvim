return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8", -- Use the stable version
		dependencies = { "nvim-lua/plenary.nvim" }, -- Required dependency
		event = "BufReadPost",

		config = function()
			local lga_actions = require("telescope-live-grep-args.actions")

			require("telescope").setup({
				defaults = {
					layout_strategy = "horizontal",
					mappings = {
						i = {
							["<C-n>"] = require("telescope.actions").move_selection_next,
							["<C-p>"] = require("telescope.actions").move_selection_previous,
							["<esc>"] = false,
						},
						n = {
							["<esc>"] = false,
							["<C-c>"] = require("telescope.actions").close,
						},
					},
				},
				pickers = {
					git_files = {
						-- theme = "dropdown",
						layout_strategy = "horizontal",
					},
				},
				extensions = {
					live_grep_args = {
						layout_strategy = "horizontal",
						auto_quoting = true,
						mappings = { -- extend mappings
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
								["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
							},
						},
					},
				},
			})
			-- Custom keybindings for Telescope
			vim.api.nvim_set_keymap(
				"n",
				"<leader>f",
				"<cmd>lua require('telescope.builtin').git_files()<cr>",
				{ noremap = true, silent = true, desc = "Telescope find files" }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>g",
				"<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>",
				{ noremap = true, silent = true, desc = "Telescope live grep" }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>tl",
				"<cmd>Telescope<cr>",
				{ noremap = true, silent = true, desc = "Telescope buffers" }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>b",
				"<cmd>Telescope buffers<cr>",
				{ noremap = true, silent = true, desc = "Telescope buffers" }
			)

			vim.api.nvim_set_keymap("n", "<C-p>", "<cmd>Telescope find_files<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rr",
				"<cmd>Telescope lsp_references<cr>",
				{ noremap = true, silent = true }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>l",
				":lua require('telescope.builtin').current_buffer_fuzzy_find({sorting_strategy = 'ascending'})<CR>",
				{ noremap = true, silent = true }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>dg",
				":lua require('telescope.builtin').diagnostics({sort_by = 'severity'})<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>de",
				":lua require('telescope.builtin').diagnostics({severity_limit = vim.diagnostic.severity.ERROR})<CR>",
				{ noremap = true, silent = true }
			)

			require("telescope").load_extension("fzf")
		end,
	},
	-- Optional dependencies, such as FZF for faster sorting
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		dependencies = { "nvim-telescope/telescope.nvim" },
	},

	{ "nvim-telescope/telescope-live-grep-args.nvim" },
}
