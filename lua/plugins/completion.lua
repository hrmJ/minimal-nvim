return {

	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		dependencies = {
			"rafamadriz/friendly-snippets",
			"moyiz/blink-emoji.nvim",
			"mikavilpas/blink-ripgrep.nvim",
		},
		version = "*",

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' for mappings similar to built-in completion
			-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
			-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
			-- See the full "keymap" documentation for information on defining your own keymap.
			keymap = {
				preset = "default",
				["<CR>"] = { "accept", "fallback" },
				["<C-b>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-k>"] = { "show_documentation", "hide_documentation" },
				["<C-q>"] = {
					function(cmp)
						cmp.show({ providers = { "snippets" } })
					end,
				},

				["<C-l>"] = {
					function(cmp)
						cmp.show({ providers = { "buffer" } })
					end,
				},

				["<C-g>"] = {
					function(cmp)
						cmp.show({ providers = { "ripgrep" } })
					end,
				},
				cmdline = {
					preset = "default",
					["<CR>"] = {},
					["<TAB>"] = { "accept", "fallback" },
				},
			},
			signature = { enabled = true },

			appearance = {
				-- Sets the fallback highlight groups to nvim-cmp's highlight groups
				-- Useful for when your theme doesn't support blink.cmp
				-- Will be removed in a future release
				use_nvim_cmp_as_default = true,
				-- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			completion = {
				ghost_text = { enabled = false },
				documentation = { auto_show = true, auto_show_delay_ms = 500 },
			},
			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lsp", "path", "buffer", "emoji" },
				providers = {
					emoji = {
						module = "blink-emoji",
						name = "Emoji",
						score_offset = 15, -- Tune by preference
					},
					ripgrep = {
						module = "blink-ripgrep",
						name = "Ripgrep",
						opts = {
							prefix_min_len = 3,
							context_size = 5,
							max_filesize = "1M",
							project_root_marker = ".git",
							search_casing = "--ignore-case",
							additional_rg_options = {},
							fallback_to_regex_highlighting = true,
							debug = false,
						},
						transform_items = function(_, items)
							for _, item in ipairs(items) do
								item.labelDetails = {
									description = "(rg)",
								}
							end
							return items
						end,
					},
				},
			},
		},
		opts_extend = { "sources.default", "sources.emoji", "sources.buffer" },
	},

	{ "rafamadriz/friendly-snippets" },
}
