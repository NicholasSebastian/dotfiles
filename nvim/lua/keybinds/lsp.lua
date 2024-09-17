-- See ':help vim.lsp.*' for documentation on the below functions.

local telescope = require("telescope.builtin")

local function format_file()
	vim.lsp.buf.format({ async = true })
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(e)
		-- Quick lookups.
		vim.keymap.set("n", "<C-space>", vim.lsp.buf.hover, { buffer = e.buf })
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { buffer = e.buf })

		-- Code formatting via none-ls.
		vim.keymap.set("n", "<leader>q", format_file, { buffer = e.buf, desc = "Format File" })

		-- Gotos.
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = e.buf, desc = "Go to Definition" })
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = e.buf, desc = "Go to Declaration" })
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = e.buf, desc = "Go to Implementation" })
		vim.keymap.set("n", "gr", telescope.lsp_references, { buffer = e.buf, desc = "Go to References" })
		vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer = e.buf, desc = "Go to Type Definition" })

		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = e.buf, desc = "Code Actions" })
		vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = e.buf, desc = "Rename All Instances" })
	end,
})
