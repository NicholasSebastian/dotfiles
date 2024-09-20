-- https://github.com/nvimtools/none-ls.nvim
-- https://github.com/folke/ts-comments.nvim

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

return {
  {
    -- Wraps linters and formatters to act like an LSP.
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      require("null-ls").setup({
        sources = require("lsp/formatters"),
        on_attach = function(client, bufnr)
          -- Auto formats on save.
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({
              group = augroup,
              buffer = bufnr,
            })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
              end,
            })
          end
        end,
      })
    end,
  },
  {
    -- Tiny formatter for code comments.
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
}
