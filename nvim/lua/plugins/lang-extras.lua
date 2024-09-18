-- https://github.com/folke/ts-comments.nvim
-- https://github.com/olexsmir/gopher.nvim
-- https://github.com/roobert/tailwindcss-colorizer-cmp.nvim

return {
  {
    -- Tiny formatter for code comments.
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
	{
		-- Adds useful commands for when working on Golang code.
		"olexsmir/gopher.nvim",
		ft = "go",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
		build = function() -- (optional) will update plugin's deps on every update
			vim.cmd.GoInstallDeps()
		end,
	},
	{
		-- Colour previews for Tailwind class autocompletion.
		"roobert/tailwindcss-colorizer-cmp.nvim",
		config = function()
			require("tailwindcss-colorizer-cmp").setup({
				color_square_width = 2,
			})
			require("cmp").config.formatting = {
				format = require("tailwindcss-colorizer-cmp").formatter,
			}
		end,
	},
}
