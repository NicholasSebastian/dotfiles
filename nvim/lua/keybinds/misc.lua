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
	end,

	-- Autocomplete keybindings.
	autocomplete = function()
		local cmp = require("cmp")
		return cmp.mapping.preset.insert({
			["<C-q>"] = cmp.mapping.abort(),
			["<C-space>"] = cmp.mapping.complete(),
			["<CR>"] = cmp.mapping.confirm({ select = true }),
		})
	end,
}
