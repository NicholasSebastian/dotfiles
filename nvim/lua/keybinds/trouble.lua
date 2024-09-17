return {
	{
		"<leader>xx",
		"<cmd>Trouble diagnostics toggle<cr>",
		desc = "Project Diagnostics",
	},
	{
		"<leader>xc",
		"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		desc = "Current File Diagnostics",
	},
	{
		"<leader>xl",
		"<cmd>Trouble loclist toggle<cr>",
		desc = "Location List",
	},
	{
		"<leader>xq",
		"<cmd>Trouble qflist toggle<cr>",
		desc = "Quickfix List",
	},
	{
		"<leader>cs",
		"<cmd>Trouble symbols toggle focus=false<cr>",
		desc = "Symbols",
	},
	{
		"<leader>cl",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "Definitions and References",
	},
}
