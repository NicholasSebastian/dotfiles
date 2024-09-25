-- Sources of linters and formatters for None-Ls.
-- Be sure to also install the corresponding packages in Mason.

local null_ls = require("null-ls")

local eslint_config = {
	condition = function(utils)
		return utils.root_has_file({
			"eslint.config.js",
			"eslint.config.mjs",
			"eslint.config.cjs",
			"eslint.config.ts",
			"eslint.config.mts",
			"eslint.config.cts",
		})
	end,
}

return {
	-- Lua
	null_ls.builtins.formatting.stylua,
	null_ls.builtins.diagnostics.selene,

	-- JavaScript
	null_ls.builtins.formatting.prettierd.with({ extra_args = { "--trailing-comma", "none" } }),
	require("none-ls.diagnostics.eslint").with(eslint_config),
	require("none-ls.code_actions.eslint").with(eslint_config),

	-- GoLang
	null_ls.builtins.formatting.gofmt, -- Already a part of Gopls.
	null_ls.builtins.formatting.goimports,
	null_ls.builtins.diagnostics.golangci_lint,
	null_ls.builtins.code_actions.gomodifytags,

	-- Python
	null_ls.builtins.formatting.black,
	null_ls.builtins.formatting.isort,
	null_ls.builtins.diagnostics.mypy,
	require("none-ls.diagnostics.ruff"),

	-- Rust
	require("none-ls.formatting.rustfmt"),

	-- CSS, SCSS, SASS, LESS
	null_ls.builtins.formatting.stylelint,
	null_ls.builtins.diagnostics.stylelint,

	-- Tailwind
	null_ls.builtins.formatting.rustywind,

	-- SQL
	null_ls.builtins.formatting.sqlfluff,
	null_ls.builtins.diagnostics.sqlfluff,

	-- Protocol Buffers
	null_ls.builtins.formatting.buf,
	null_ls.builtins.diagnostics.buf,

	-- Makefiles
	null_ls.builtins.diagnostics.checkmake,

	-- Docker files
	null_ls.builtins.diagnostics.hadolint,

	-- YAML
	null_ls.builtins.formatting.yamlfmt,
	require("none-ls.diagnostics.yamllint"),

	-- Git
	null_ls.builtins.code_actions.gitsigns, -- No need to install anything.

	-- Markdown
	null_ls.builtins.formatting.remark,
	null_ls.builtins.diagnostics.markdownlint,

	-- Shell scripts
	null_ls.builtins.formatting.shfmt,

	-- HTML
	-- null_ls.builtins.formatting.tidy, -- Not available in Mason.
	-- null_ls.builtins.diagnostics.tidy, -- Not available in Mason.
}
