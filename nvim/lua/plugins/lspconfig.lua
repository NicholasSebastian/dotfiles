return {
  "neovim/nvim-lspconfig",
  opts = function()
    local keys = require("lazyvim.plugins.lsp.keymaps").get()

    -- Remap some of the default LSP keymaps
    keys[#keys + 1] = { "<C-space>", vim.lsp.buf.hover }
    keys[#keys + 1] = { "<C-k>", vim.lsp.buf.signature_help }
    keys[#keys + 1] = { "K", false }
  end,
}
