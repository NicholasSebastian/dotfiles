-- https://github.com/nvimtools/none-ls.nvim
-- Wraps linters and formatters to act like an LSP.
-- Provides code formatting functionality.

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		require("null-ls").setup({
			sources = require("lsp/linters"),
			on_attach = function(client, bufnr)
				-- Auto formats on save.
				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_clear_autocmds({
						group = augroup,
						buffer = bufnr,
					})
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr })
						end,
					})
				end
			end,
		})
	end,
}
