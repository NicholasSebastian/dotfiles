local cmp = require("cmp")

local function compare_underscores(entry1, entry2)
  local _, entry1_under = entry1.completion_item.label:find("^_+")
  local _, entry2_under = entry2.completion_item.label:find("^_+")
  entry1_under = entry1_under or 0
  entry2_under = entry2_under or 0
  if entry1_under > entry2_under then
    return false
  elseif entry1_under < entry2_under then
    return true
  end
end

return {
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip", option = { use_show_condition = false } },
  }, {
    { name = "nvim_lua" },                  -- For editing Neovim lua configs.
    { name = "buffer",  max_item_count = 10 }, -- The contents of the current open file.
    { name = "path" },                      -- File system paths.
  }),
  formatting = {
    expandable_indicator = true,
    fields = { "abbr", "kind", "menu" },
    format = require("lspkind").cmp_format({ -- Makes the dropdowns look fancier.
      with_text = true,
      menu = {
        buffer = "[buf]",
        nvim_lsp = "[LSP]",
        nvim_lua = "[api]",
        path = "[path]",
        luasnip = "[snip]",
      },
    }),
  },
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      compare_underscores, -- Nice for Python, cause it got lots of stuff that start with underscores.
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
}
