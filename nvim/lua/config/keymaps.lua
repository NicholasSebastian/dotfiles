-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move lines with Arrow keys too.
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Pasting without replacing the current copy register.
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "lossless paste" })

-- Delete these default keymaps so we can override them.
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Right>")

-- Navigate between splits.
vim.keymap.set("n", "<C-Left>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
vim.keymap.set("n", "<C-Down>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
vim.keymap.set("n", "<C-Up>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
vim.keymap.set("n", "<C-Right>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

-- Shortcut to go to Neotree. Old habits die hard.
vim.keymap.set("n", "<C-b>", "<cmd>Neotree filesystem reveal<cr>", { desc = "Reveal NeoTree Explorer" })
