-- lua/plugins/lsp.lua
return {
	-- Mason installer
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},

	-- Mason LSPconfig bridge
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "ts_ls" }, -- Automatically install the TypeScript LSP
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- LSP setup
			local lspconfig = require("lspconfig")

			-- Key mappings for LSP
			local function on_attach(client, bufnr)
				-- Keybinding options
				local opts = { noremap = true, silent = true, buffer = bufnr }
				-- Show diagnostics on hover
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				-- Go to definition
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				-- Go to declaration
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				-- Show symbol signature information
				vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
				-- Rename symbol
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				-- Trigger diagnostics float with <leader>e
				vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
				-- Go to next diagnostic
				vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				-- Go to previous diagnostic
				vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
				-- Code actions
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				-- List references
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
			end

			-- Setup ts_ls (TypeScript Language Server)
			lspconfig.ts_ls.setup({
				on_attach = on_attach,
			})

			-- LSP diagnostics configuration
			vim.diagnostic.config({
				signs = false, -- Disable signs in the gutter
				virtual_text = false, -- Disable inline text
				underline = true, -- Enable underlining (undercurls)
				update_in_insert = false, -- Don't show diagnostics in insert mode
				severity_sort = true, -- Sort diagnostics by severity
			})
		end,
	},
}
