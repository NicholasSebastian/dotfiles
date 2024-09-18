-- https://github.com/folke/which-key.nvim
-- https://github.com/folke/trouble.nvim
-- https://github.com/nvim-pack/nvim-spectre
-- https://github.com/mg979/vim-visual-multi

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
		end,
	},
	{
		-- Allows for multiline cursors like in VScode.
		"mg979/vim-visual-multi",
		branch = "master",
	},
}
