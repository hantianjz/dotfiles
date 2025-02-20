return {
  'smoka7/hop.nvim',
  enabled = false,
  config = function()
    require('hop').setup()
    vim.keymap.set('n', '<Leader><space>', "<cmd>:HopWord<cr>", {})
  end

}
