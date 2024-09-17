-- https://github.com/folke/which-key.nvim
-- https://github.com/folke/trouble.nvim
-- https://github.com/nvim-pack/nvim-spectre
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
			},
		},
	},
	{
		-- Project errors and warnings panel.
		"folke/trouble.nvim",
		opts = {},
		cmd = "Trouble",
		keys = require("keybinds/trouble"),
	},
	{
		-- Find and replace panel.
		"nvim-pack/nvim-spectre",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("spectre").setup()
			require("keybinds/misc").spectre()
		end,
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
}
