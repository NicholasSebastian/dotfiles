local config = require("lspconfig")
local autocomplete = require("cmp_nvim_lsp").default_capabilities()

config.cssls.setup({ capabilities = autocomplete })
config.dockerls.setup({ capabilities = autocomplete })
config.eslint.setup({ capabilities = autocomplete })
config.gopls.setup({ capabilities = autocomplete })
config.html.setup({ capabilities = autocomplete })
config.htmx.setup({ capabilities = autocomplete })
config.jsonls.setup({ capabilities = autocomplete })
config.pyright.setup({ capabilities = autocomplete })
config.svelte.setup({ capabilities = autocomplete })
config.tailwindcss.setup({ capabilities = autocomplete })
config.ts_ls.setup({ capabilities = autocomplete })
config.templ.setup({ capabilities = autocomplete })

config.lua_ls.setup({
  capabilities = autocomplete,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" }, -- To get rid of "undefined global vim" warnings.
      },
    },
  },
})

config.rust_analyzer.setup({
  capabilities = autocomplete,
  settings = {
    ["rust-analyzer"] = {},
  },
})
