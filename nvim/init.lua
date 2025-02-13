require("config.lazy")
local conform = require("conform")

-- stylua: ignore
conform.formatters.prettier = {
  prepend_args = {
    "--print-width", "120",
    "--trailing-comma", "none",
    "--bracket-same-line",
    "--arrow-parens", "avoid",
  },
}

-- Set Golang specific indent options.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  group = vim.api.nvim_create_augroup("Golang_indent", { clear = true }),
  callback = function()
    vim.opt.expandtab = false
    vim.opt.tabstop = 4
    vim.opt.softtabstop = 4
    vim.opt.shiftwidth = 4
  end,
})

-- Tile the window when first entering Neovim.
vim.api.nvim_create_autocmd("UIEnter", {
  group = vim.api.nvim_create_augroup("Hyprland_tile_on_open", { clear = true }),
  once = true,
  callback = function()
    vim.cmd("silent !hyprctl dispatch settiled")
  end,
})

-- Reveal Neotree when first entering Neovim.
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

-- Reveal Neotree whenever we enter a new tab.
vim.api.nvim_create_autocmd("TabNew", {
  group = vim.api.nvim_create_augroup("Neotree_on_new_tab", { clear = true }),
  desc = "Open Neo-tree automatically in any new tab",
  callback = function()
    vim.schedule(function()
      vim.cmd("Neotree filesystem reveal")
    end)
  end,
})
