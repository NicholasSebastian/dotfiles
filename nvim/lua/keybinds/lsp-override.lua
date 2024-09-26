local show_crate_docs = function()
	if vim.fn.expand("%:t") == "Cargo.toml" and require("crates").popup_available() then
		require("crates").show_popup()
	else
		vim.lsp.buf.hover()
	end
end

return {
	csharp = {
		"gd",
		require("omnisharp_extended").telescope_lsp_definitions,
		desc = "Go to Definition",
	},
	toml = {
		"K",
		show_crate_docs,
		desc = "Show Crate Documentation",
	},
}
