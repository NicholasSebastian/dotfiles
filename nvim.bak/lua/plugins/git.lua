-- https://github.com/lewis6991/gitsigns.nvim
-- https://github.com/kdheepak/lazygit.nvim

return {
  {
    -- A window to help manage git operations.
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>l", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
    },
  },
	{
		-- Shows git decorations inside the editor.
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			on_attach = require("keybinds/git"),
		},
	},
}
