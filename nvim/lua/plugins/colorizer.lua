-- https://github.com/norcalli/nvim-colorizer.lua
-- https://github.com/roobert/tailwindcss-colorizer-cmp.nvim

return {
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
				RGB = true, -- #RGB hex codes
				RRGGBB = true, -- #RRGGBB hex codes
				names = true, -- "Name" codes like Blue
				RRGGBBAA = true, -- #RRGGBBAA hex codes
				rgb_fn = true, -- CSS rgb() and rgba() functions
				hsl_fn = true, -- CSS hsl() and hsla() functions
				css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
				css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn
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
}
