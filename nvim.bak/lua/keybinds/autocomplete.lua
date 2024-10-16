local cmp = require("cmp")

return cmp.mapping.preset.insert({
	["<Esc>"] = cmp.mapping.abort(),
	["<C-space>"] = cmp.mapping.complete(),
	["<CR>"] = cmp.mapping.confirm({
		behavior = cmp.ConfirmBehavior.Insert,
		select = true,
	}),
})
