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

if vim.env.HERDR_ENV == "1"
    and vim.env.HERDR_PANE_ID
    and vim.env.HERDR_SOCKET_PATH then
  return {
    name = "herdr-nvim-navigator",
    dir = vim.fn.stdpath("config"),
    config = function()
      require("herdr_navigator").setup()
    end,
  }
end

return tmux_navigator
