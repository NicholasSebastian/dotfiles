-- Setup line numbering.
vim.opt.nu = true

-- Indent by 2 spaces.
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

-- Disable line wraps.
vim.opt.wrap = false

-- Disable backups but save the undo history to a file.
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Highlight searches per character.
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Enable fancy colours.
vim.opt.termguicolors = true

-- Distance the cursor scroll position from the ends of a file.
vim.opt.scrolloff = 8

-- Show the sign column (next to the line numbering on the left).
vim.opt.signcolumn = "yes"

-- Faster updates.
vim.opt.updatetime = 50

-- Disable NetRW because its ugly.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
