-- https://github.com/catppuccin/nvim
-- https://github.com/stevearc/dressing.nvim
-- https://github.com/akinsho/bufferline.nvim
-- https://github.com/nvim-lualine/lualine.nvim

return {
	{
		-- Catppuccin Mocha theme.
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "mocha",
			integrations = {
				overseer = true,
			},
		},
		config = function()
			vim.cmd.colorscheme("catppuccin")
		end,
	},
	{
		-- Makes some of the UI look nicer.
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		-- Adds a cool bar at the bottom.
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"letieu/harpoon-lualine",
		},
		opts = {
			theme = "dracula",
			extensions = { "lazy", "mason", "fzf", "neo-tree", "trouble", "overseer" },
			sections = {
				lualine_x = {
					{ "harpoon2", color_active = { fg = "#89b4fb" } },
				},
			},
			options = {
				component_separators = "",
				section_separators = { left = "", right = "" },
			},
		},
	},
	{
		-- Makes the tabs look better.
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			options = {
				mode = "tabs",
				separator_style = "slant",
			},
		},
	},
}
