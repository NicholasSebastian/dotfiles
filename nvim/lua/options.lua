-- Setup line numbering column.
vim.opt.nu = true
vim.opt.signcolumn = "yes"

-- Cursor settings.
vim.opt.cursorline = true
vim.opt.scrolloff = 8

-- Indent by 2 spaces.
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

-- Allow the backspace to behave the way its supposed to.
vim.opt.backspace = "indent,eol,start"

-- Disable line wraps.
vim.opt.wrap = false

-- Disable backups but save the undo history to a file.
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Use the system clipboard as the default register.
vim.opt.clipboard:append("unnamedplus")

-- Highlight searches per character.
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Ignore case when searching, unless when searching with mixed case.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Enable fancy colours.
vim.opt.termguicolors = true

-- New split windows will appear to the right/bottom side.
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Faster updates.
vim.opt.updatetime = 50

-- Disable NetRW because its ugly.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
