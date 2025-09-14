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

	-- {
	-- 	"kevinhwang91/nvim-ufo",
	-- 	dependencies = { "kevinhwang91/promise-async" },
	-- 	lazy = false,
	-- 	config = function()
	-- 		vim.o.foldcolumn = "3"
	-- 		vim.o.foldlevel = 99
	-- 		vim.o.foldlevelstart = 3
	-- 		vim.o.foldenable = true
	--
	-- 		-- local capabilities = vim.lsp.protocol.make_client_capabilities()
	-- 		-- capabilities.textDocument.foldingRange = {
	-- 		-- 	dynamicRegistration = false,
	-- 		-- 	lineFoldingOnly = true,
	-- 		-- }
	-- 		-- local language_servers = vim.lsp.get_clients() -- or list servers manually like {'gopls', 'clangd'}
	-- 		-- for _, ls in ipairs(language_servers) do
	-- 		-- 	require("lspconfig")[ls].setup({
	-- 		-- 		capabilities = capabilities,
	-- 		-- 		-- you can add other fields for setting up lsp server in this table
	-- 		-- 	})
	-- 		-- end
	-- 		-- require("ufo").setup()
	--
	-- 		require("ufo").setup({
	-- 			provider_selector = function(bufnr, filetype, buftype)
	-- 				return { "treesitter", "indent" }
	-- 			end,
	-- 		})
	-- 	end,
	-- },
}
