-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- The file tree explorer sidebar thing.

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	opts = {
		sources = { "filesystem", "buffers", "git_status" },
		filesystem = {
			filtered_items = {
				visible = true,
				show_hidden_count = true,
				hide_dotfiles = false,
				hide_gitignored = false,
				hide_by_name = {},
				never_show = {
					".DS_Store",
					".git",
					"$RECYCLE.BIN",
					".Trash-1000",
					"thumbs.db",
				},
			},
		},
	},
	config = function()
		vim.cmd("Neotree filesystem reveal left", {})
    require("keybinds/misc").neotree()
	end,
}
