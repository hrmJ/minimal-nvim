-- Key mappings for LSP (attached via LspAttach autocmd)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local bufnr = args.buf
		local opts = { noremap = true, silent = true, buffer = bufnr }

		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", function()
			local params = vim.lsp.util.make_position_params()
			vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, config)
				if err then
					vim.notify("Error on definition: " .. err.message, vim.log.levels.ERROR)
					return
				end
				if not result or vim.tbl_isempty(result) then
					vim.notify("Definition not found", vim.log.levels.INFO)
					return
				end
				local filtered = {}
				for _, res in ipairs(result) do
					local uri = res.uri or res.targetUri
					if not string.match(vim.uri_to_fname(uri), "node_modules") then
						table.insert(filtered, res)
					end
				end
				if vim.tbl_isempty(filtered) then
					filtered = result
				end
				vim.lsp.util.jump_to_location(filtered[1], "utf-8")
				if #filtered > 1 then
					vim.lsp.util.set_qflist(vim.lsp.util.locations_to_items(filtered))
					vim.api.nvim_command("copen")
				end
			end)
		end, opts)
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	end,
})

-- Diagnostics
vim.diagnostic.config({
	signs = false,
	virtual_text = false,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

return {
	-- Mason installer
	{
		"williamboman/mason.nvim",
		event = "BufRead",
		config = function()
			require("mason").setup()
		end,
	},

	-- Mason LSPconfig bridge
	{
		"williamboman/mason-lspconfig.nvim",
		event = "BufRead",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "ts_ls", "jsonls" },
			})
		end,
	},

	-- SchemaStore for JSON schema catalog
	{
		"b0o/schemastore.nvim",
		lazy = true,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp", "b0o/schemastore.nvim" },
		event = "BufRead",
		config = function()
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
			})
			vim.lsp.config("basedpyright", {})
			vim.lsp.config("ts_ls", {})
			vim.lsp.config("eslint", {})
			vim.lsp.config("jsonls", {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			})
			vim.lsp.enable({ "ts_ls", "eslint", "jsonls" })
			vim.lsp.enable("oxlint")
			vim.lsp.config("oxlint", {
				root_markers = { ".git" },
			})
		end,
	},

	-- Fidget for LSP progress indicator
	{
		"j-hui/fidget.nvim",
		event = "BufRead",
		config = function()
			require("fidget").setup({
				text = {
					spinner = "dots",
				},
				align = {
					bottom = true,
				},
				window = {
					blend = 0,
				},
			})
		end,
	},

	{
		"stevearc/conform.nvim",
		event = "BufRead",
		opts = {},
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					javascript = { "prettierd", "prettier", stop_after_first = true },
					typescript = { "prettierd", "prettier", stop_after_first = true },
					typescriptreact = { "prettierd", "prettier", stop_after_first = true },
					-- python = { "black", prepend_args = { "--fast" } },
					python = { "autopep8" },
				},
			})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function(args)
					require("conform").format({ bufnr = args.buf })
				end,
			})
		end,
	},
}
