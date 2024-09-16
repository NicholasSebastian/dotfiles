-- Be sure to install the below linters/formatters in Mason.

local null_ls = require("null-ls")

return {
  -- Lua
  null_ls.builtins.formatting.stylua,

  -- JavaScript
  null_ls.builtins.formatting.prettier,
  require("none-ls.diagnostics.eslint_d"),

  -- Python
  null_ls.builtins.formatting.black,
  null_ls.builtins.formatting.isort,

  -- Tailwind
  null_ls.builtins.formatting.rustywind,
}
