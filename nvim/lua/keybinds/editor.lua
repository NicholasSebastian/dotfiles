return {
  trouble = {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Project Diagnostics",
    },
    {
      "<leader>xc",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Current File Diagnostics",
    },
    {
      "<leader>xl",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List",
    },
    {
      "<leader>xq",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List",
    },
    {
      "<leader>cs",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols",
    },
    {
      "<leader>cl",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "Definitions and References",
    },
  },
  overseer = {
    {
      "<leader>ow",
      "<cmd>OverseerToggle<cr>",
      desc = "Task list",
    },
    {
      "<leader>oo",
      "<cmd>OverseerRun<cr>",
      desc = "Run task",
    },
    {
      "<leader>oq",
      "<cmd>OverseerQuickAction<cr>",
      desc = "Action recent task",
    },
    {
      "<leader>oi",
      "<cmd>OverseerInfo<cr>",
      desc = "Overseer Info",
    },
    {
      "<leader>ob",
      "<cmd>OverseerBuild<cr>",
      desc = "Task builder",
    },
    {
      "<leader>ot",
      "<cmd>OverseerTaskAction<cr>",
      desc = "Task action",
    },
    {
      "<leader>oc",
      "<cmd>OverseerClearCache<cr>",
      desc = "Clear cache",
    },
  },
}
