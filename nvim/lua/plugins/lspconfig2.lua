return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    local on_publish_diagnostics = vim.lsp.diagnostic.on_publish_diagnostics
    opts.servers.bashls = vim.tbl_deep_extend("force", opts.servers.bashls or {}, {
      handlers = {
        ["textDocument/publishDiagnostics"] = function(err, res, ...)
          local file_name = vim.fn.fnamemodify(vim.uri_to_fname(res.uri), ":t")
          if string.match(file_name, "^%.env") == nil then
            return on_publish_diagnostics(err, res, ...)
          end
        end,
      },
    })
  end,
}
