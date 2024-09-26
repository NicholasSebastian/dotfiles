-- https://github.com/ThePrimeagen/refactoring.nvim
-- ThePrimeagen's plugin. Helps with refactoring code.

return {
	"ThePrimeagen/refactoring.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-telescope/telescope.nvim",
	},
	keys = require("keybinds/refactoring"),
	opts = {
		prompt_func_return_type = {
			go = false,
			java = false,
			cpp = false,
			c = false,
			h = false,
			hpp = false,
			cxx = false,
		},
		prompt_func_param_type = {
			go = false,
			java = false,
			cpp = false,
			c = false,
			h = false,
			hpp = false,
			cxx = false,
		},
		printf_statements = {},
		print_var_statements = {},
		show_success_message = true,
	},
	config = function()
		require("telescope").load_extension("refactoring")
	end,
}
