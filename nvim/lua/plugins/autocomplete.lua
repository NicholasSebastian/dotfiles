-- https://github.com/hrsh7th/nvim-cmp
-- https://github.com/L3MON4D3/LuaSnip
-- https://github.com/saadparwaiz1/cmp_luasnip
-- https://github.com/sar/friendly-snippets.nvim
-- https://github.com/hrsh7th/cmp-nvim-lsp

return {
	{ "hrsh7th/cmp-nvim-lsp" }, -- Autocomplete source for the Neovim LSP.
	{
		"L3MON4D3/LuaSnip", -- Autocomplete source for nvim-cmp.
		dependencies = {
			"saadparwaiz1/cmp_luasnip", -- Autocomplete engine for LuaSnip.
			"rafamadriz/friendly-snippets", -- The actual snippets package for cmp_luasnip.
		},
		config = function()
			-- Load the VScode-like snippets by friendly-snippets.
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	{
		-- Autocomplete for Neovim. This will defer to LuaSnip.
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = require("keybinds/misc").autocomplete(),
				sources = cmp.config.sources({
					{ name = "luasnip" },
				}, {
					{ name = "nvim_lsp" },
					{ name = "path" },
					{ name = "buffer" },
				}),
			})
		end,
	},
}
