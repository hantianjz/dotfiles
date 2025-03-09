---@mod plugins.tmux Tmux navigation integration
---
--- Configures vim-tmux-navigator for seamless navigation between
--- Neovim splits and Tmux panes using Ctrl + hjkl.

---@type LazySpec
return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  keys = {
    {
      "<C-h>",
      function() vim.cmd([[:TmuxNavigateLeft]]) end,
      silent = true,
      desc = "Navigate to left pane"
    },
    {
      "<C-j>",
      function() vim.cmd([[:TmuxNavigateDown]]) end,
      silent = true,
      desc = "Navigate to bottom pane"
    },
    {
      "<C-k>",
      function() vim.cmd([[:TmuxNavigateUp]]) end,
      silent = true,
      desc = "Navigate to top pane"
    },
    {
      "<C-l>",
      function() vim.cmd([[:TmuxNavigateRight]]) end,
      silent = true,
      desc = "Navigate to right pane"
    },
  },
}