-- https://github.com/nvim-treesitter/nvim-treesitter
-- AST generator for syntax highlighting and other LSPs.

return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			ensure_installed = require("lsp/installed").treesitter,
			auto_install = true,
      sync_install = false,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
