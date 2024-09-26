-- https://github.com/folke/which-key.nvim
-- https://github.com/folke/trouble.nvim

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
}
