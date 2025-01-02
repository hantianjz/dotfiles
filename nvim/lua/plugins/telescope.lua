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
      { '<leader>b',  function() require('telescope.builtin').buffers() end,         desc = "Current buffers" },
      { '<leader>vh', function() require('telescope.builtin').help_tags() end,       desc = "Vim help tag" },
      { '<leader>d',  function() require('telescope.builtin').diagnostics() end,     desc = "Diagnostics info" },
      { '<leader>lf', function() require('telescope.builtin').lsp_references() end,  desc = "Show symbol references" },
      { '<leader>ld', function() require('telescope.builtin').lsp_definitions() end, desc = "Show symbol definition" },
      { '<leader>o',  function() require('telescope.builtin').builtin() end,         desc = "Telescope builtin" },
      {
        '<leader>vc',
        function()
          require('telescope.builtin').find_files({
            cwd = vim.fn.stdpath("config")
          })
        end,
        desc = "Find files for nvim plugins"
      },
      {
        '<leader>vp',
        function()
          require('telescope.builtin').find_files({
            ---@diagnostic disable-next-line: param-type-mismatch
            cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
          })
        end,
        desc = "Find files for nvim plugins"
      },
    },

    config = function()
      local actions = require("telescope.actions")
      -- local open_with_trouble = require("trouble.sources.telescope").open

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
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--follow", "--exclude", ".git" },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,                   -- false will only do exact matching
            iverride_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          }
        }
      })

      require('telescope').load_extension('fzf')
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
