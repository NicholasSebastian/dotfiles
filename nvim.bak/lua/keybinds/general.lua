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

local move_down = ":m '>+1<CR>gv=gv"
local move_up = ":m '<-2<CR>gv=gv"

-- Moving the current selection vertically.
vim.keymap.set("v", "J", move_down)
vim.keymap.set("v", "K", move_up)
vim.keymap.set("v", "<S-Down>", move_down)
vim.keymap.set("v", "<S-Up>", move_up)

-- Deleting the current selection.
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete Selection" })

-- Pasting without replacing the current copy register.
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Lossless Paste" })

-- Tab controls.
vim.keymap.set("n", "<leader>tt", ":tabnew<CR>", { desc = "Open a new tab" })
vim.keymap.set("n", "<leader>tf", ":tabnew %<CR>", { desc = "Open the current file in a new tab" })
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close the current tab" })
vim.keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "Navigate to the next tab" })
vim.keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "Navigate to the previous tab" })

-- Split screen.
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split Windows Horizontally" })
vim.keymap.set("n", "<leader>ss", ":vsplit<CR>", { desc = "Split Windows Vertically" })
vim.keymap.set("n", "<leader>sx", ":close<CR>", { desc = "Close Current Split" })

-- Navigate between splits.
vim.keymap.set("n", "<A-Left>", "<C-w>h")
vim.keymap.set("n", "<A-Down>", "<C-w>j")
vim.keymap.set("n", "<A-Up>", "<C-w>k")
vim.keymap.set("n", "<A-Right>", "<C-w>l")
