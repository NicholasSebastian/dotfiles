return {
  "akinsho/bufferline.nvim",
  keys = { -- Add arrow keys for bufferline navigation.
    { "<S-Left>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "<S-Right>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
  },
}
