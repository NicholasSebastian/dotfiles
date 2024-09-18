-- https://github.com/nvim-telescope/telescope.nvim
-- https://github.com/nvim-telescope/telescope-ui-select.nvim
-- The file finder you can access through Ctrl+P.

return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",

			-- This apparently makes it faster.
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},
	{
		-- This makes it so that vim.ui.select uses Telescope as a picker instead.
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			local telescope = require("telescope")
			telescope.setup({ defaults = { path_display = { "smart" } } })
			telescope.load_extension("fzf")
			telescope.load_extension("ui-select")
		end,
	},
}
