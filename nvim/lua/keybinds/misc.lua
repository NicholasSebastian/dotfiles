local builtin = require("telescope.builtin")

local open_spectre = '<cmd>lua require("spectre").toggle()<CR>'
local spectre_current_n = '<cmd>lua require("spectre").open_visual({ select_word=true })<CR>'
local spectre_current_v = '<esc><cmd>lua require("spectre").open_visual()<CR>'
local spectre_file = '<cmd>lua require("spectre").open_file_search({ select_word=true })<CR>'

-- NeoTree keybindings.
vim.keymap.set("n", "<C-b>", ":Neotree<CR>")
vim.keymap.set("n", "<leader>b", ":Neotree<CR>", { desc = "Open the File Tree" })

-- Telescope keybindings.
vim.keymap.set("n", "<C-p>", builtin.find_files)
vim.keymap.set("n", "<leader>?", builtin.help_tags, { desc = "Open Help Manual" })
vim.keymap.set("n", "<leader>p", builtin.find_files, { desc = "Open Telescope" })
vim.keymap.set("n", "<leader>ff", builtin.live_grep, { desc = "Live Grep Search" })
vim.keymap.set("n", "<leader>fc", builtin.grep_string, { desc = "Search Current Word" })
vim.keymap.set("n", "<leader>fs", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Search in Files" })
