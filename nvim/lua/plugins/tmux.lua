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
      mode = { "n", "i", "t" },
      silent = true,
      desc = "Navigate to left pane"
    },
    {
      "<C-j>",
      function() vim.cmd([[:TmuxNavigateDown]]) end,
      mode = { "n", "t" },
      silent = true,
      desc = "Navigate to bottom pane"
    },
    {
      "<C-k>",
      function() vim.cmd([[:TmuxNavigateUp]]) end,
      mode = { "n", "t" },
      silent = true,
      desc = "Navigate to top pane"
    },
    {
      "<C-l>",
      function() vim.cmd([[:TmuxNavigateRight]]) end,
      mode = { "n", "t" },
      silent = true,
      desc = "Navigate to right pane"
    },
  },
}
