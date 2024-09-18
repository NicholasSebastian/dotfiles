-- https://github.com/windwp/nvim-ts-autotag
-- https://github.com/olexsmir/gopher.nvim
-- https://github.com/roobert/tailwindcss-colorizer-cmp.nvim

return {
  {
    -- Automatically opens/closes/renames html, jsx, tsx, svelte, etc. tag pairs.
    "windwp/nvim-ts-autotag",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("nvim-ts-autotag").setup({})
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
}
