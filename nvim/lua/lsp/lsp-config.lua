local config = require("lspconfig")
local util = require("lspconfig/util")
local autocomplete = require("cmp_nvim_lsp").default_capabilities()
local keybinds = require("keybinds/lsp-override")
local schemastore = require("schemastore")

-- HTML, HTMX, Svelte, and Templ.
config.html.setup({ capabilities = autocomplete })
config.htmx.setup({ capabilities = autocomplete })
config.svelte.setup({ capabilities = autocomplete })
config.templ.setup({ capabilities = autocomplete })
config.emmet_language_server.setup({ capabilities = autocomplete })

-- CSS Variables, CSS Modules, SCSS, Sass, and Tailwind.
config.css_variables.setup({ capabilities = autocomplete })
config.cssmodules_ls.setup({ capabilities = autocomplete })
config.somesass_ls.setup({ capabilities = autocomplete })
config.tailwindcss.setup({ capabilities = autocomplete })

-- Javascript.
config.eslint.setup({
	capabilities = autocomplete,
	filetypes = { "javascript", "javascriptreact", "javascript.jsx", "vue", "svelte", "astro" },
})

-- Typescript.
config.ts_ls.setup({
	capabilities = autocomplete,
	filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
})

-- Python.
config.pyright.setup({ capabilities = autocomplete })
-- config.ruff.setup({ capabilities = autocomplete }) -- Overlapping functionality with Pyright I think.

-- Bash and Fish shell script.
config.bashls.setup({ capabilities = autocomplete })

-- Protocol Buffers.
config.pbls.setup({ capabilities = autocomplete })

-- TOML.
config.taplo.setup({ capabilities = autocomplete, keys = keybinds.toml })

-- Markdown.
config.marksman.setup({ capabilities = autocomplete })

-- Docker and Docker Compose file.
config.dockerls.setup({ capabilities = autocomplete })
config.docker_compose_language_service.setup({ capabilities = autocomplete })

-- Nginx config file.
config.nginx_language_server.setup({ capabilities = autocomplete })

-- Hyprland config file.
config.hyprls.setup({ capabilities = autocomplete })

-- CSS.
config.cssls.setup({
	capabilities = autocomplete,
	settings = {
		css = {
			lint = {
				unknownAtRules = "ignore",
			},
		},
	},
})

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
			gofumpt = true,
			codelenses = {
				gc_details = false,
				generate = true,
				regenerate_cgo = true,
				run_govulncheck = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
				vendor = true,
			},
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
			analyses = {
				fieldalignment = true,
				nilness = true,
				unusedparams = true,
				unusedwrite = true,
				useany = true,
			},
			usePlaceholders = true,
			completeUnimported = true,
			staticcheck = true,
			semanticTokens = true,
		},
	},
	on_attach = function(client, _)
		-- workaround for gopls not supporting semanticTokensProvider
		-- https://github.com/golang/go/issues/54531#issuecomment-1464982242
		if not client.server_capabilities.semanticTokensProvider then
			local semantic = client.config.capabilities.textDocument.semanticTokens
			client.server_capabilities.semanticTokensProvider = {
				full = true,
				range = true,
				legend = {
					tokenTypes = semantic.tokenTypes,
					tokenModifiers = semantic.tokenModifiers,
				},
			}
		end
	end,
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

-- C-Sharp.
config.omnisharp.setup({
	enable_roslyn_analyzers = true,
	organize_imports_on_format = true,
	enable_import_completion = true,
	handlers = {
		["textDocument/definition"] = function(...)
			return require("omnisharp_extended").handler(...)
		end,
	},
	keys = keybinds.csharp,
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
			validate = true,
			format = { enable = true },
			keyOrdering = false,
			schemaStore = {
				enable = false,
				url = "",
			},
		},
	},
})
