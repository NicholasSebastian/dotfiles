-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- The file tree explorer sidebar thing.

local function open_neotree()
	vim.schedule(function()
		vim.cmd("Neotree filesystem reveal")
	end)
end

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			sources = { "filesystem", "buffers", "git_status" },
			close_if_last_window = true,
			window = {
				position = "left",
				width = 40,
			},
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
		})

		-- Open Neotree on launch and on new tabs.
		open_neotree()
		vim.api.nvim_create_autocmd("TabNew", { pattern = "*", callback = open_neotree })
	end,
}
