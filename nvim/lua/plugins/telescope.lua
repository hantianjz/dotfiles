return {
  'nvim-telescope/telescope.nvim',
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim'
  },
  keys = {
    { '<leader>t',  function() require('telescope.builtin').find_files() end },
    { '<leader>s',  function() require('telescope.builtin').live_grep() end },
    { '<leader>b',  function() require('telescope.builtin').buffers() end },
    { '<leader>lf', function() require('telescope.builtin').lsp_references() end },
    { '<leader>ld', function() require('telescope.builtin').lsp_definitions() end },
    { '<leader>fh', function() require('telescope.builtin').help_tags() end },
  },
  configs = function()
    local actions = require("telescope.actions")

    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<esc>"] = actions.close,
          },
        },
      },
      pickers = {
        find_files = {
          find_command = { "fd", "--type", "f", "--strip-cwd-prefix" }
        },
      },
    })
  end
}
