-- https://github.com/catppuccin/nvim
-- Catppuccin Mocha theme.

return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	opts = {
		flavour = "mocha",
	},
	config = function()
		vim.cmd.colorscheme("catppuccin")
	end,
}
