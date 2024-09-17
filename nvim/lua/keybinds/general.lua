-- Set the Leader key bindings.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Normie shortcuts.
vim.keymap.set({ "n", "v", "i" }, "<C-s>", "<Esc>:w<CR>") -- Save file.
vim.keymap.set("n", "<C-a>", "ggVG") -- Select all.
vim.keymap.set("v", "<C-c>", "y<Esc>i") -- Copy selection.
vim.keymap.set("v", "<C-x>", "d<Esc>i") -- Cut selection.
vim.keymap.set({ "n", "v" }, "<C-v>", "pi") -- Paste.
vim.keymap.set("i", "<C-v>", "<Esc>pi") -- Paste.
vim.keymap.set("n", "<C-z>", "u") -- Undo.
vim.keymap.set("i", "<C-z>", "<Esc>ui") -- Undo.
vim.keymap.set("i", "<S-Tab>", "<Esc>^i<BS>") -- Outdent.

-- Moving the current selection vertically.
local move_down = ":m '>+1<CR>gv=gv"
local move_up = ":m '<-2<CR>gv=gv"

vim.keymap.set("v", "J", move_down)
vim.keymap.set("v", "K", move_up)
vim.keymap.set("v", "<S-Down>", move_down)
vim.keymap.set("v", "<S-Up>", move_up)

-- Deleting the current selection.
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete Selection" })

-- Pasting without replacing the current copy register.
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Lossless Paste" })
