-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  group = vim.api.nvim_create_augroup("Neotree_on_open", { clear = true }),
  once = true,
  callback = function()
    if vim.fn.argc() == 0 then
      vim.schedule(function()
        vim.cmd("Neotree filesystem reveal")
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("TabNew", {
  group = vim.api.nvim_create_augroup("Neotree_on_new_tab", { clear = true }),
  desc = "Open Neo-tree automatically in any new tab",
  callback = function()
    vim.schedule(function()
      vim.cmd("Neotree filesystem reveal")
    end)
  end,
})
