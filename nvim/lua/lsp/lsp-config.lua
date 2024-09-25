local config = require("lspconfig")
local util = require("lspconfig/util")
local autocomplete = require("cmp_nvim_lsp").default_capabilities()
local schemastore = require("schemastore")

-- HTML, HTMX, Svelte, and Templ.
config.html.setup({ capabilities = autocomplete })
config.htmx.setup({ capabilities = autocomplete })
config.svelte.setup({ capabilities = autocomplete })
config.templ.setup({ capabilities = autocomplete })
config.emmet_language_server.setup({ capabilities = autocomplete })

-- CSS, SCSS, Sass, and Tailwind.
config.cssls.setup({ capabilities = autocomplete })
config.cssmodules_ls.setup({ capabilities = autocomplete })
config.css_variables.setup({ capabilities = autocomplete })
config.somesass_ls.setup({ capabilities = autocomplete })
config.tailwindcss.setup({ capabilities = autocomplete })

-- Javascript and Typescript.
config.eslint.setup({ capabilities = autocomplete })
config.ts_ls.setup({ capabilities = autocomplete })

-- Python.
config.pyright.setup({ capabilities = autocomplete })
-- config.ruff.setup({ capabilities = autocomplete }) -- Overlapping functionality with Pyright.

-- Bash and Fish shell script.
config.bashls.setup({ capabilities = autocomplete })

-- SQL.
config.sqls.setup({ capabilities = autocomplete }) -- Kinda shit.

-- Protocol Buffers.
config.pbls.setup({ capabilities = autocomplete })

-- Markdown.
config.marksman.setup({ capabilities = autocomplete })

-- Docker and Docker Compose file.
config.dockerls.setup({ capabilities = autocomplete })
config.docker_compose_language_service.setup({ capabilities = autocomplete })

-- Nginx config file.
config.nginx_language_server.setup({ capabilities = autocomplete })

-- Hyprland config file.
config.hyprls.setup({ capabilities = autocomplete })

-- Lua.
config.lua_ls.setup({
	capabilities = autocomplete,
	settings = {
		Lua = {
			diagnostics = {
				enable = false, -- Let selene handle linting.
			},
		},
	},
})

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

-- JSON.
config.jsonls.setup({
	capabilities = autocomplete,
	settings = {
		json = {
			schemas = schemastore.json.schemas(),
			validate = { enable = true },
			format = { enable = true },
		},
	},
})

-- YAML.
config.yamlls.setup({
	capabilities = autocomplete,
	settings = {
		redhat = {
			telemetry = { enabled = false },
		},
		yaml = {
			schemas = schemastore.yaml.schemas(),
			validate = { enable = true },
			format = { enable = true },
			keyOrdering = { enable = false },
			schemaStore = {
				enable = false,
				url = "",
			},
		},
	},
})
