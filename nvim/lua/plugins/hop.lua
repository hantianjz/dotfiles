return {
  'smoka7/hop.nvim',
  enables = false,
  config = function()
    require('hop').setup()
    vim.keymap.set('n', '<Leader><space>', "<cmd>:HopWord<cr>", {})
  end

}
