return {
	-- NeoTree keybindings.
	neotree = function()
		vim.keymap.set("n", "<C-b>", ":Neotree<CR>")
		vim.keymap.set("n", "<leader>b", ":Neotree<CR>", { desc = "Open the File Tree" })
	end,

	-- Telescope keybindings.
	telescope = function()
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<C-p>", builtin.find_files)
		vim.keymap.set("n", "<leader>p", builtin.find_files, { desc = "Open Telescope" })
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
		vim.keymap.set("n", "<leader>fs", function()
			builtin.grep_string({ search = vim.fn.input("Grep > ") })
		end, { desc = "Search in Files" })
		vim.keymap.set("n", "<leader>?", builtin.help_tags, { desc = "Open Help Manual" })
	end,

	-- Spectre keybindings.
	spectre = function()
		local open_spectre = '<cmd>lua require("spectre").toggle()<CR>'
		local spectre_current_n = '<cmd>lua require("spectre").open_visual({ select_word=true })<CR>'
		local spectre_current_v = '<esc><cmd>lua require("spectre").open_visual()<CR>'
		local spectre_file = '<cmd>lua require("spectre").open_file_search({ select_word=true })<CR>'

		vim.keymap.set("n", "<leader>ffp", open_spectre, { desc = "Find and Replace" })
		vim.keymap.set("n", "<leader>ffw", spectre_current_n, { desc = "Replace Current Word" })
		vim.keymap.set("v", "<leader>ffw", spectre_current_v, { desc = "Replace Current Word" })
		vim.keymap.set("n", "<leader>fff", spectre_file, { desc = "Replace in Current File" })
	end,

	-- Autocomplete keybindings.
	autocomplete = function()
		local cmp = require("cmp")
		return cmp.mapping.preset.insert({
			["<Esc>"] = cmp.mapping.abort(),
			["<C-space>"] = cmp.mapping.complete(),
			["<CR>"] = cmp.mapping.confirm({
				behavior = cmp.ConfirmBehavior.Insert,
				select = true,
			}),
		})
	end,
}
