return {
  'smoka7/hop.nvim',
  enables = false,
  config = function()
    require('hop').setup()
    vim.keymap.set('n', 'f',
      function()
        require 'hop'.hint_char1({
          direction = require 'hop.hint'.HintDirection.AFTER_CURSOR,
          current_line_only = true
        })
      end,
      {})

    vim.keymap.set('n', 'F',
      function()
        require 'hop'.hint_char1({
          direction = require 'hop.hint'.HintDirection.BEFORE_CURSOR,
          current_line_only = true
        })
      end,
      {})

    vim.keymap.set('n', '<Leader><space>', "<cmd>:HopChar1<cr>", {})
  end

}
