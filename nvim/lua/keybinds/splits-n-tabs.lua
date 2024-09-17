local new_tab = function()
	vim.cmd("tabnew", {}) -- Opens a new tab.
	vim.cmd("Alpha", {}) -- Shows the Alpha dashboard.
	vim.schedule(function()
		vim.cmd("Neotree reveal", {}) -- Shows the Neotree file tree AFTER Alpha is done with its shit.
	end)
end

-- Tab controls.
vim.keymap.set("n", "<leader>to", new_tab, { desc = "Open a new tab" })
vim.keymap.set("n", "<leader>tf", ":tabnew %<CR>:Neotree reveal<CR>", { desc = "Open the current file in a new tab" })
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close the current tab" })
vim.keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "Navigate to the next tab" })
vim.keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "Navigate to the previous tab" })

-- Split screen.
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split Windows Horizontally" })
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split Windows Vertically" })
vim.keymap.set("n", "<leader>sx", ":close<CR>", { desc = "Close current Split" })

-- Navigate between splits.
vim.keymap.set("n", "<A-Left>", "<C-w>h")
vim.keymap.set("n", "<A-Down>", "<C-w>j")
vim.keymap.set("n", "<A-Up>", "<C-w>k")
vim.keymap.set("n", "<A-Right>", "<C-w>l")
