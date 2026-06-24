return {
	{
		"nvim-telescope/telescope.nvim",
		-- tag = "0.1.8", -- Use the stable version
		dependencies = { "nvim-lua/plenary.nvim" }, -- Required dependency
		event = "BufReadPost",

		config = function()
			local lga_actions = require("telescope-live-grep-args.actions")
			local utils = require("telescope-utils")

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
					buffers = {
						layout_strategy = "horizontal",
						mappings = {
							i = {
								["<C-d>"] = require("telescope.actions").delete_buffer,
								["<C-t>"] = utils.open_in_tmux_pane,
								["<C-s>"] = utils.open_in_tmux_pane_vertical,
							},
							n = {
								["<C-d>"] = require("telescope.actions").delete_buffer,
								["<C-t>"] = utils.open_in_tmux_pane,
								["<C-s>"] = utils.open_in_tmux_pane_vertical,
							},
						},
						path_display = utils.path_display,
					},
					git_files = {
						layout_strategy = "horizontal",
						mappings = {
							i = {
								["<C-t>"] = utils.open_in_tmux_pane,
								["<C-s>"] = utils.open_in_tmux_pane_vertical,
								["<C-w>"] = utils.open_in_tmux_win,
							},
							n = {
								["<C-t>"] = utils.open_in_tmux_pane,
								["<C-s>"] = utils.open_in_tmux_pane_vertical,
								["<C-w>"] = utils.open_in_tmux_win,
							},
						},
						path_display = utils.path_display,
					},
				},
				extensions = {
					live_grep_args = {
						hidden = true,
						layout_strategy = "horizontal",
						additional_args = function(_)
							return { "--hidden" }
						end,
						path_display = utils.path_display,
						auto_quoting = true,
						mappings = {
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
								["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
								["<C-t>"] = utils.open_in_tmux_pane,
								["<C-s>"] = utils.open_in_tmux_pane_vertical,
							},
							n = {
								["<C-t>"] = utils.open_in_tmux_pane,
								["<C-s>"] = utils.open_in_tmux_pane_vertical,
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
				"<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args({'--hidden'})<cr>",
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

			vim.api.nvim_set_keymap("n", "<leader>tr", ":Telescope resume<CR><Esc>", { noremap = true, silent = true })

			vim.api.nvim_set_keymap(
				"n",
				"<leader>tp",
				":lua require('telescope-tmux-panes').pick_tmux_pane()<CR>",
				{ noremap = true, silent = true, desc = "Telescope tmux panes" }
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

	{
		"startup-nvim/startup.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
		},
		lazy = false,
		config = function()
			require("startup").setup()
		end,
	},
}
