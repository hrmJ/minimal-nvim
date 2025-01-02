function goto_definition_filtered()
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
		-- Filter out results from node_modules
		local filtered_result = {}
		for _, res in ipairs(result) do
			local uri = res.uri or res.targetUri
			local path = vim.uri_to_fname(uri)
			if not string.match(path, "node_modules") then
				table.insert(filtered_result, res)
			end
		end
		if vim.tbl_isempty(filtered_result) then
			-- If no results outside node_modules, use original result
			filtered_result = result
		end
		vim.lsp.util.jump_to_location(filtered_result[1], "utf-8")
		if #filtered_result > 1 then
			vim.lsp.util.set_qflist(vim.lsp.util.locations_to_items(filtered_result))
			vim.api.nvim_command("copen")
		end
	end)
end

-- lua/plugins/lsp.lua
return {
	-- Mason installer
	{
		"williamboman/mason.nvim",
		event = "BufRead", -- Load only when reading a file
		config = function()
			require("mason").setup()
		end,
	},

	-- Mason LSPconfig bridge
	{
		"williamboman/mason-lspconfig.nvim",
		event = "BufRead", -- Load only when reading a file
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "ts_ls" }, -- Automatically install the TypeScript LSP
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },
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
				vim.api.nvim_set_keymap(
					"n",
					"gd",
					"<cmd>lua goto_definition_filtered()<CR>",
					{ noremap = true, silent = true }
				)

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

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			-- lspconfig.ts_ls.setup({ capabilities = capabilities })

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
	-- Fidget for LSP progress indicator
	{
		"j-hui/fidget.nvim",
		event = "BufRead", -- Load only when reading a file
		config = function()
			require("fidget").setup({
				text = {
					spinner = "dots", -- Choose from different spinner styles
				},
				align = {
					bottom = true, -- Align fidget to the bottom
				},
				window = {
					blend = 0, -- Keep window opaque (adjust for transparency)
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
