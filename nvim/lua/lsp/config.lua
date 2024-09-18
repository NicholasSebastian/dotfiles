local config = require("lspconfig")
local util = require("lspconfig/util")
local autocomplete = require("cmp_nvim_lsp").default_capabilities()

-- HTML, HTMX, Svelte, and Templ.
config.html.setup({ capabilities = autocomplete })
config.htmx.setup({ capabilities = autocomplete })
config.svelte.setup({ capabilities = autocomplete })
config.templ.setup({ capabilities = autocomplete })

-- CSS and Tailwind.
config.cssls.setup({ capabilities = autocomplete })
config.cssmodules_ls.setup({ capabilities = autocomplete })
config.css_variables.setup({ capabilities = autocomplete })
config.tailwindcss.setup({ capabilities = autocomplete })

-- Javascript and Typescript.
config.eslint.setup({ capabilities = autocomplete })
config.ts_ls.setup({ capabilities = autocomplete })

-- Lua.
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

-- Python.
config.pyright.setup({ capabilities = autocomplete })
config.ruff.setup({ capabilities = autocomplete })

-- Golang.
config.gopls.setup({
	capabilities = autocomplete,
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_dir = util.root_pattern("go.work", "go.mod", ".git"),
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = {
				unusedparams = true,
			},
		},
	},
})

-- Rust.
config.rust_analyzer.setup({
	capabilities = autocomplete,
	filetypes = { "rust" },
	root_dir = util.root_pattern("Cargo.toml"),
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
			},
		},
	},
})

-- Misc.
config.jsonls.setup({ capabilities = autocomplete })
config.dockerls.setup({ capabilities = autocomplete })
config.nginx_language_server.setup({ capabilities = autocomplete })
config.hyprls.setup({ capabilities = autocomplete })
