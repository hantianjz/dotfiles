---@mod plugins.tmux Multiplexer navigation integration
---
--- Selects the navigator for the multiplexer that launched Neovim.

---@type LazySpec
local tmux_navigator = {
  'christoomey/vim-tmux-navigator',
  cond = function()
    return vim.env.TMUX ~= nil
  end,
  keys = {
    {
      "<C-h>",
      function() vim.cmd([[TmuxNavigateLeft]]) end,
      silent = true,
      desc = "Navigate to left pane"
    },
    {
      "<C-j>",
      function() vim.cmd([[TmuxNavigateDown]]) end,
      silent = true,
      desc = "Navigate to bottom pane"
    },
    {
      "<C-k>",
      function() vim.cmd([[TmuxNavigateUp]]) end,
      silent = true,
      desc = "Navigate to top pane"
    },
    {
      "<C-l>",
      function() vim.cmd([[TmuxNavigateRight]]) end,
      silent = true,
      desc = "Navigate to right pane"
    },
  },
  config = function()
    vim.keymap.set('t', '<C-l>', '<C-\\><C-n>:TmuxNavigateRight<CR>', { noremap = true, silent = true })
    vim.keymap.set('t', '<C-k>', '<C-\\><C-n>:TmuxNavigateUp<CR>', { noremap = true, silent = true })
    vim.keymap.set('t', '<C-j>', '<C-\\><C-n>:TmuxNavigateDown<CR>', { noremap = true, silent = true })
    vim.keymap.set('t', '<C-h>', '<C-\\><C-n>:TmuxNavigateLeft<CR>', { noremap = true, silent = true })
  end,
}

local herdr_navigator = {
  "paulbkim-dev/vim-herdr-navigation",
  cond = function()
    return vim.env.HERDR_ENV == "1"
        and vim.env.HERDR_PANE_ID ~= nil
        and vim.env.HERDR_SOCKET_PATH ~= nil
  end,
  config = function(plugin)
    dofile(plugin.dir .. "/editor/nvim.lua")
  end,
}

return { tmux_navigator, herdr_navigator }
