return {
  {
    'nvim-telescope/telescope.nvim',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim'
    },
    keys = {
      { '<leader>t',  function() require('telescope.builtin').find_files() end,       desc = "Find files" },
      { '<leader>s',  function() require('telescope.builtin').live_grep() end,        desc = "Grep for string" },
      { '<leader>b',  function() require('telescope.builtin').buffers() end,          desc = "Current buffers" },
      { '<leader>lf', function() require('telescope.builtin').lsp_references() end,   desc = "Show symbol references" },
      { '<leader>ld', function() require('telescope.builtin').lsp_definitions() end,  desc = "Show symbol definition" },
      { '<leader>fh', function() require('telescope.builtin').help_tags() end,        desc = "Vim help tag" },
    },
    config = function()
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
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require("telescope").setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
              -- even more opts
            }

          }
        }
      }
      -- To get ui-select loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      require("telescope").load_extension("ui-select")
    end
  }
}
