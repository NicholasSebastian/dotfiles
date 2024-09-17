-- https://github.com/nvim-lualine/lualine.nvim
-- The cool bar at the bottom.

return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    theme = "dracula",
    extensions = { "mason", "neo-tree", "trouble" },
  },
}
