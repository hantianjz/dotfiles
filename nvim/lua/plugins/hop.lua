return {
  'smoka7/hop.nvim',
  enables = false,
  config = function()
    require('hop').setup()
    vim.keymap.set('n', 'f',
      function()
        require 'hop'.hint_words({})
      end,
      {})
  end

}
