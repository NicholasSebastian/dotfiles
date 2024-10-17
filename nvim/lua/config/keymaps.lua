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

-- Delete some more unused keymaps.
vim.keymap.del("n", "<Leader>l")
vim.keymap.del("n", "<Leader>L")
vim.keymap.del("n", "<Leader>K")
vim.keymap.del("n", "<Leader>`")
vim.keymap.del("n", "<Leader>,")

-- Jump to buffers with number keys. Feels just like Harpoon.
vim.keymap.set("n", "1", "<cmd>BufferLineGoToBuffer 1<cr>", { desc = "Go to Buffer 1" })
vim.keymap.set("n", "2", "<cmd>BufferLineGoToBuffer 2<cr>", { desc = "Go to Buffer 2" })
vim.keymap.set("n", "3", "<cmd>BufferLineGoToBuffer 3<cr>", { desc = "Go to Buffer 3" })
vim.keymap.set("n", "4", "<cmd>BufferLineGoToBuffer 4<cr>", { desc = "Go to Buffer 4" })
vim.keymap.set("n", "5", "<cmd>BufferLineGoToBuffer 5<cr>", { desc = "Go to Buffer 5" })
vim.keymap.set("n", "6", "<cmd>BufferLineGoToBuffer 6<cr>", { desc = "Go to Buffer 6" })
vim.keymap.set("n", "7", "<cmd>BufferLineGoToBuffer 7<cr>", { desc = "Go to Buffer 7" })
vim.keymap.set("n", "8", "<cmd>BufferLineGoToBuffer 8<cr>", { desc = "Go to Buffer 8" })
vim.keymap.set("n", "9", "<cmd>BufferLineGoToBuffer 9<cr>", { desc = "Go to Buffer 9" })
