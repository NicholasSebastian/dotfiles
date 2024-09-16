-- https://github.com/mg979/vim-visual-multi
-- https://github.com/folke/ts-comments.nvim

return {
	{
		-- Cheatsheet for all the keybindings.
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			triggers = {
				{ "<auto>", mode = "nixsotc" },
				{ "<C>", mode = "n" },
			},
		},
	},
	{
		-- Allows for multiline cursors like in VScode.
		"mg979/vim-visual-multi",
		branch = "master",
	},
	{
		-- Tiny formatter for code comments.
		"folke/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
		enabled = vim.fn.has("nvim-0.10.0") == 1,
	},
	{
		-- Colour previews for Tailwind class autocompletion.
		"roobert/tailwindcss-colorizer-cmp.nvim",
		config = function()
			require("tailwindcss-colorizer-cmp").setup({
				color_square_width = 2,
			})
			require("cmp").config.formatting = {
				format = require("tailwindcss-colorizer-cmp").formatter,
			}
		end,
	},
}
