-- Be sure to install the below linters/formatters in Mason.

local null_ls = require("null-ls")

return {
  -- Lua
  null_ls.builtins.formatting.stylua,

  -- JavaScript
  null_ls.builtins.formatting.prettierd,
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
}
