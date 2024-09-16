-- https://github.com/windwp/nvim-autopairs
-- https://github.com/windwp/nvim-ts-autotag
-- Automatically closes and renames Brackets and HTML tag pairs.

return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },
  {
    "windwp/nvim-ts-autotag",
    dependencies = {
      "nvim-treesitter/nvim-treesitter"
    },
    config = function()
      require("nvim-ts-autotag").setup({})
    end
  }
}
