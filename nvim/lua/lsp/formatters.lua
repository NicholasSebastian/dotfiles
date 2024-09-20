-- Sources of linters and formatters for None-Ls.
-- Be sure to also install the corresponding packages in Mason.

local null_ls = require("null-ls")

return {
  -- Lua
  null_ls.builtins.formatting.stylua,

  -- JavaScript
  null_ls.builtins.formatting.prettierd.with({ extra_args = { "--trailing-comma", "none" } }),
  require("none-ls.diagnostics.eslint_d"),
  require("none-ls.code_actions.eslint_d"),

  -- GoLang
  null_ls.builtins.formatting.gofmt,
  null_ls.builtins.formatting.goimports, -- go install golang.org/x/tools/cmd/goimports@latest

  -- Python
  null_ls.builtins.formatting.black,
  null_ls.builtins.formatting.isort,
  null_ls.builtins.diagnostics.mypy,
  require("none-ls.diagnostics.ruff"),

  -- Tailwind
  null_ls.builtins.formatting.rustywind,

  -- Git
  null_ls.builtins.code_actions.gitsigns,
}
