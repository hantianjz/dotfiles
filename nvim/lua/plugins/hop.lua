---@mod plugins.hop Easy motion plugin configuration
---
--- Configures the hop.nvim plugin for easy motion navigation.
--- Currently disabled but configured for quick word jumping.

---@type LazySpec
return {
  'smoka7/hop.nvim',
  enabled = false,
  keys = {
    {
      '<Leader><space>',
      "<cmd>:HopWord<cr>",
      desc = "Hop to word"
    },
  },
  config = function()
    require('hop').setup()
  end
}