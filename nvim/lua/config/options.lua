-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false -- Disable relative line numbers.
vim.opt.list = false
vim.opt.scrolloff = 8 -- Lines of vertical spacing from the edges of the window.
vim.opt.softtabstop = 2
vim.opt.backspace = "indent,eol,start" -- Allow the backspace to behave the way its supposed to.
vim.opt.updatetime = 50 -- Faster updates.

-- Highlight searches per character.
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Ignore case when searching, unless when searching with mixed case.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Disable NetRW because its ugly.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
