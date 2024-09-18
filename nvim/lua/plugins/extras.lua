-- https://github.com/windwp/nvim-autopairs
-- https://github.com/kylechui/nvim-surround
-- https://github.com/numToStr/Comment.nvim
-- https://github.com/mg979/vim-visual-multi

return {
	{
		-- Automatically opens/closes bracket pairs.
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
	{
		-- Adds useful keybindings for commenting blocks of code.
		"numToStr/Comment.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		config = function()
			local extra = require("ts_context_commentstring.integrations.comment_nvim")
			require("Comment").setup({
				opleader = { line = "<leader>cc", block = "<leader>cb" },
				pre_hook = extra.create_pre_hook(), -- for commenting html, jsx, tsx, svelte files.
			})
		end,
	},
	{
    -- Adds useful keybindings for surrounding blocks of text.
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		-- Allows for multiline cursors like in VScode.
		"mg979/vim-visual-multi",
		branch = "master",
	},
}