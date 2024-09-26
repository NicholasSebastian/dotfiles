-- https://github.com/windwp/nvim-ts-autotag
-- https://github.com/olexsmir/gopher.nvim
-- https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file

return {
  {
    -- Automatically opens/closes/renames html, jsx, tsx, svelte, etc. tag pairs.
    "windwp/nvim-ts-autotag",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("nvim-ts-autotag").setup({})
    end,
  },
  {
    -- Adds useful commands for when working on Golang code.
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
    build = function() -- (optional) will update plugin's deps on every update
      vim.cmd.GoInstallDeps()
    end,
  },
  {
    -- Extends C# omnisharp LSP functionality.
    "Hoffs/omnisharp-extended-lsp.nvim",
    lazy = true,
  },
  {
    -- Adds a venv selector for Python.
    "linux-cultist/venv-selector.nvim",
    branch = "regexp", -- Use this branch for the new version
    cmd = "VenvSelect",
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
    ft = "python",
    keys = {
      { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" },
    },
  },
  {
    -- Adds autocompletion and a context menu for Cargo.toml files.
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
      },
    },
  },
  {
    -- Adds schemas for common JSON/YAML files (e.g. eslintrc, prettierrc, tsconfig, etc).
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
}
