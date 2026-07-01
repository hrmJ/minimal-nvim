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
			vim.keymap.set("n", "<leader>mb", function()
				MiniPick.builtin.buffers({}, { mappings = buffer_mappings })
			end, { noremap = true, silent = true })
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
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	{
		"timantipov/md-table-tidy.nvim",
		lazy = false,
		opts = {
			padding = 1, -- number of spaces for cell padding
			keymap = {
				table_tidy = "<leader>tt", -- key for command :TableTidy<CR>
				table_tidy_all = "<leader>ta", -- key for command :TableTidyAll<CR>
			},
		},
		config = function()
			require("md-table-tidy").setup()
		end,
	},
	{
		"folke/zen-mode.nvim",
		lazy = false,
		config = function()
			require("zen-mode").setup()
		end,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},

	{
		"3rd/image.nvim",
		build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
		opts = {
			processor = "magick_cli",
		},
		config = function()
			require("image").setup({
				backend = "kitty", -- or "ueberzug" or "sixel"
				processor = "magick_cli", -- or "magick_rock"
				integrations = {
					markdown = {
						enabled = true,
						clear_in_insert_mode = false,
						download_remote_images = true,
						only_render_image_at_cursor = false,
						only_render_image_at_cursor_mode = "popup", -- or "inline"
						floating_windows = false, -- if true, images will be rendered in floating markdown windows
						filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
					},
					asciidoc = {
						enabled = true,
						clear_in_insert_mode = false,
						download_remote_images = true,
						only_render_image_at_cursor = false,
						only_render_image_at_cursor_mode = "popup",
						floating_windows = false,
						filetypes = { "asciidoc", "adoc" },
					},
					neorg = {
						enabled = true,
						filetypes = { "norg" },
					},
					rst = {
						enabled = true,
					},
					typst = {
						enabled = true,
						filetypes = { "typst" },
					},
					html = {
						enabled = false,
					},
					css = {
						enabled = false,
					},
				},
				max_width = nil,
				max_height = nil,
				max_width_window_percentage = nil,
				max_height_window_percentage = 50,
				scale_factor = 1.0,
				kitty_direct_chunk_size = 4096, -- chunk size for direct Kitty graphics protocol transmission
				window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
				window_overlap_clear_ft_ignore = {
					"cmp_menu",
					"cmp_docs",
					"snacks_notif",
					"scrollview",
					"scrollview_sign",
				},
				editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
				tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
				hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
			})
		end,
	},
	{
		"3rd/diagram.nvim",

		lazy = false,
		dependencies = {
			{ "3rd/image.nvim", opts = {} }, -- you'd probably want to configure image.nvim manually instead of doing this
		},
		opts = { -- you can just pass {}, defaults below
			events = {
				render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
				clear_buffer = { "BufLeave" },
			},
			renderer_options = {
				mermaid = {
					background = nil, -- nil | "transparent" | "white" | "#hex"
					theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
					scale = 1, -- nil | 1 (default) | 2  | 3 | ...
					width = nil, -- nil | 800 | 400 | ...
					height = nil, -- nil | 600 | 300 | ...
					cli_args = nil, -- nil | { "--no-sandbox" } | { "-p", "/path/to/puppeteer" } | ...
				},
				plantuml = {
					charset = nil,
					cli_args = nil, -- nil | { "-Djava.awt.headless=true" } | ...
				},
				d2 = {
					theme_id = nil,
					dark_theme_id = nil,
					scale = nil,
					layout = nil,
					sketch = nil,
					cli_args = nil, -- nil | { "--pad", "0" } | ...
				},
				gnuplot = {
					size = nil, -- nil | "800,600" | ...
					font = nil, -- nil | "Arial,12" | ...
					theme = nil, -- nil | "light" | "dark" | custom theme string
					cli_args = nil, -- nil | { "-p" } | { "-c", "config.plt" } | ...
				},
			},
		},
		config = function()
			require("diagram").setup({
				integrations = {
					require("diagram.integrations.markdown"),
					require("diagram.integrations.neorg"),
				},
				renderer_options = {
					mermaid = {
						theme = "forest",
					},
					plantuml = {
						charset = "utf-8",
					},
					d2 = {
						theme_id = 1,
					},
					gnuplot = {
						theme = "dark",
						size = "800,600",
					},
				},
			})
		end,
	},
}
