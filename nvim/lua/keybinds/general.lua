-- Set the Leader key bindings.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Normie shortcuts.
vim.keymap.set({ "n", "v", "i" }, "<C-s>", "<Esc>:w<CR>") -- Save file.
vim.keymap.set("n", "<C-a>", "ggVG")                      -- Select all.
vim.keymap.set("v", "<C-c>", "y<Esc>i")                   -- Copy selection.
vim.keymap.set("v", "<C-x>", "d<Esc>i")                   -- Cut selection.
vim.keymap.set({ "n", "v" }, "<C-v>", "pi")               -- Paste.
vim.keymap.set("i", "<C-v>", "<Esc>pi")                   -- Paste.
vim.keymap.set("n", "<C-z>", "u")                         -- Undo.
vim.keymap.set("i", "<C-z>", "<Esc>ui")                   -- Undo.
vim.keymap.set("i", "<S-Tab>", "<Esc>^i<BS>")             -- Outdent.

-- Moving the current selection vertically.
local moveDown = ":m '>+1<CR>gv=gv"
local moveUp = ":m '<-2<CR>gv=gv"

vim.keymap.set("v", "J", moveDown)
vim.keymap.set("v", "K", moveUp)
vim.keymap.set("v", "<S-Down>", moveDown)
vim.keymap.set("v", "<S-Up>", moveUp)

-- Deleting the current selection.
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete Selection" })

-- Pasting without replacing the current copy register.
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Lossless Paste" })

-- Copying to the system clipboard.
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to System Clipboard" })

-- Split screen.
vim.keymap.set("n", "<leader>ss", ":split<CR>", { desc = "Split Windows Horizontally" })
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split Windows Vertically" })

-- Navigate between screens.
vim.keymap.set("n", "<A-Left>", "<C-w>h")
vim.keymap.set("n", "<A-Down>", "<C-w>j")
vim.keymap.set("n", "<A-Up>", "<C-w>k")
vim.keymap.set("n", "<A-Right>", "<C-w>l")
