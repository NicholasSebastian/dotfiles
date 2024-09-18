-- https://github.com/catppuccin/nvim
-- https://github.com/stevearc/dressing.nvim
-- https://github.com/akinsho/bufferline.nvim
-- https://github.com/nvim-lualine/lualine.nvim

return {
  {
    -- Catppuccin Mocha theme.
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
    },
    config = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    -- Makes some of the UI look nicer.
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    -- Makes the tabs look better.
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      options = {
        mode = "tabs",
        separator_style = "slant",
      },
    },
  },
  {
    -- Adds a cool bar at the bottom.
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      theme = "dracula",
      extensions = { "mason", "neo-tree", "trouble" },
    },
  },
}
