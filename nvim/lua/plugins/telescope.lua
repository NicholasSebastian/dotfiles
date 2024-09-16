-- https://github.com/nvim-telescope/telescope.nvim
-- https://github.com/nvim-telescope/telescope-ui-select.nvim
-- The file finder you can access through Ctrl+P.

return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("keybinds/misc").telescope()
		end,
	},
	{
		-- This makes it so that vim.ui.select uses Telescope as a picker instead.
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").load_extension("ui-select")
		end,
	},
}
