-- https://github.com/windwp/nvim-ts-autotag
-- https://github.com/olexsmir/gopher.nvim
-- https://github.com/norcalli/nvim-colorizer.lua
-- https://github.com/roobert/tailwindcss-colorizer-cmp.nvim
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
    -- Colour highlighting.
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "html",
        "javascriptreact",
        "typescriptreact",
        "css",
        "scss",
        "sass",
        "less",
      }, {
        RGB = true,      -- #RGB hex codes
        RRGGBB = true,   -- #RRGGBB hex codes
        names = true,    -- "Name" codes like Blue
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        rgb_fn = true,   -- CSS rgb() and rgba() functions
        hsl_fn = true,   -- CSS hsl() and hsla() functions
        css = true,      -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = false,  -- Enable all CSS *functions*: rgb_fn, hsl_fn
        mode = "background", -- Set the display mode.
      })
    end,
  },
  {
    -- Colour previews for Tailwind class autocompletion.
    "roobert/tailwindcss-colorizer-cmp.nvim",
    config = function()
      require("tailwindcss-colorizer-cmp").setup({
        color_square_width = 2,
      })
      require("cmp").config.formatting = {
        format = require("tailwindcss-colorizer-cmp").formatter,
      }
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
    -- Adds schemas for common JSON/YAML files (e.g. eslintrc, prettierrc, tsconfig, etc).
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
}
