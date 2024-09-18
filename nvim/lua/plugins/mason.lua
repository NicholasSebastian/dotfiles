-- https://github.com/williamboman/mason.nvim
-- https://github.com/williamboman/mason-lspconfig.nvim
-- https://github.com/neovim/nvim-lspconfig

return {
	{
		-- Package manager for LSPs, linters, formatters, etc.
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		-- Default configs for the Neovim LSP.
		"neovim/nvim-lspconfig",
		config = function()
			require("lsp/config")
			require("keybinds/lsp")
		end,
	},
	{
		-- Bridges Mason and lspconfig.
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"williamboman/mason.nvim",
		},
		opts = {
			ensure_installed = require("lsp/languages"),
		},
	},
}
