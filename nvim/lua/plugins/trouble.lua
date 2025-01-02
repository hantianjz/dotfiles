return {
  "folke/trouble.nvim",
  opts = {}, -- for default options, refer to the configuration section for custom setup.
  cmd = "Trouble",
  enabled = false,
  keys = {
    {
      '<leader>d',
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)"
    },
    {
      '<leader>D',
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Buffer Diagnostics Whole project (Trouble)"
    },
  }
}
