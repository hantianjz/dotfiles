return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  keys = {
    { "<silent> <C-h>", function() vim.cmd([[:TmuxNavigateLeft]]) end },
    { "<silent> <C-j>", function() vim.cmd([[:TmuxNavigateDown]]) end },
    { "<silent> <C-k>", function() vim.cmd([[:TmuxNavigateUp]]) end },
    { "<silent> <C-l>", function() vim.cmd([[:TmuxNavigateRight]]) end },
  },
}
