-- https://github.com/folke/which-key.nvim
-- https://github.com/folke/trouble.nvim

return {
	{
		-- Cheatsheet for all the keybindings.
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			spec = require("keybinds/cheatsheet"),
			triggers = {
				{ "<auto>", mode = "nixsotc" },
			},
		},
	},
	{
		-- Project errors and warnings panel.
		"folke/trouble.nvim",
		cmd = "Trouble",
		keys = require("keybinds/trouble"),
		opts = {},
	},
	{
		-- Command Runner window.
		"stevearc/overseer.nvim",
		keys = require("keybinds/overseer"),
		cmd = {
			"OverseerOpen",
			"OverseerClose",
			"OverseerToggle",
			"OverseerSaveBundle",
			"OverseerLoadBundle",
			"OverseerDeleteBundle",
			"OverseerRunCmd",
			"OverseerRun",
			"OverseerInfo",
			"OverseerBuild",
			"OverseerQuickAction",
			"OverseerTaskAction",
			"OverseerClearCache",
		},
		opts = {
			dap = false,
			form = { win_opts = { winblend = 0 } },
			confirm = { win_opts = { winblend = 0 } },
			task_win = { win_opts = { winblend = 0 } },
			task_list = {
				bindings = {
					["<C-h>"] = false,
					["<C-j>"] = false,
					["<C-k>"] = false,
					["<C-l>"] = false,
				},
			},
		},
	},
}
