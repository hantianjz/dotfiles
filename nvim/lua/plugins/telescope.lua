return {
  {
    'nvim-telescope/telescope.nvim',
    lazy = false,
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
    keys = {
      { '<leader>t',  function() require('telescope.builtin').find_files() end,      desc = "Find files" },
      { '<leader>g',  function() require('telescope.builtin').git_files() end,       desc = "Get files" },
      { '<leader>s',  function() require('telescope.builtin').live_grep() end,       desc = "Live grep for string" },
      { '<leader>e',  function() require('telescope.builtin').grep_string() end,     desc = "Grep current string" },
      { '<leader>b',  function() require('telescope.builtin').buffers() end,         desc = "Current buffers" },
      { '<leader>lf', function() require('telescope.builtin').lsp_references() end,  desc = "Show symbol references" },
      { '<leader>ld', function() require('telescope.builtin').lsp_definitions() end, desc = "Show symbol definition" },
      { '<leader>H',  function() require('telescope.builtin').help_tags() end,       desc = "Vim help tag" },
      { '<leader>D',  function() require('telescope.builtin').diagnostics() end,     desc = "Diagnostics info" },
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
        extensions = {
          fzf = {
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          }
        }
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
