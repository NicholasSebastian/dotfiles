local crates = require("crates")
local csharp = require("omnisharp_extended")

local show_crate_docs = function()
	if vim.fn.expand("%:t") == "Cargo.toml" and crates.popup_available() then
		crates.show_popup()
	else
		vim.lsp.buf.hover()
	end
end

return {
	toml = {
		{ "<C-k>", show_crate_docs, desc = "Show Crate Documentation" },
	},
	csharp = {
		{ "gd", csharp.telescope_lsp_definition, desc = "Go to Definition" },
		{ "gi", csharp.telescope_lsp_implementation, desc = "Go to Implementation" },
		{ "gr", csharp.telescope_lsp_references, desc = "Go to References" },
		{ "gt", csharp.telescope_lsp_type_definition, desc = "Go to Type Definition" },
	},
}
