-- https://github.com/catppuccin/nvim
-- https://github.com/stevearc/dressing.nvim
-- https://github.com/goolord/alpha-nvim

return {
	{
		-- Catppuccin Mocha theme.
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "mocha",
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
}
