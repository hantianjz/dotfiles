---@mod plugins.completion Completion engine configuration
---
--- Configures blink.cmp, a fast completion engine written in Rust.
--- Includes support for various completion sources including LSP,
--- Copilot, snippets, and more.

---@type LazySpec[]
return {
  {
    "Saghen/blink.cmp",
    version = '*',
    dependencies = {
      -- Snippet Engine
      { "fang2hou/blink-copilot" },
      {

        'L3MON4D3/LuaSnip',
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require("luasnip.loaders.from_vscode").lazy_load()
            end
          }
        },
        opt = {
          history = true
        }
      },
    },

    ---@type blink.cmp.Config
    opts = {
      -- Keymaps Configuration
      keymap = {
        preset = 'none',
        ['<C-t>'] = { 'show', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'select_and_accept', 'fallback' },
        ['<C-w>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
      },

      -- Command Line Completion
      cmdline = { enabled = false },

      -- Completion Sources Configuration
      sources = {
        -- Default sources for all filetypes
        default = { 'copilot', 'lsp', 'path', 'snippets', 'buffer' },

        -- Filetype-specific sources
        per_filetype = {
          oil = { 'path' },
        },

        -- Provider-specific configurations
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
        },
      },

      -- Signature Help
      signature = { enabled = true },

      -- Snippets Configuration
      snippets = {
        expand = function(snippet)
          require('luasnip').lsp_expand(snippet)
        end,
        active = function(filter)
          if filter and filter.direction then
            return require('luasnip').jumpable(filter.direction)
          end
          return require('luasnip').in_snippet()
        end,
        jump = function(direction)
          require('luasnip').jump(direction)
        end,
      },

      -- Completion Behavior Configuration
      completion = {
        -- Documentation Display
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 1000,
        },

        -- Ghost Text
        ghost_text = {
          enabled = true,
          show_without_selection = false
        },

        -- Auto Brackets
        accept = {
          auto_brackets = { enabled = true },
        },

        -- List Configuration
        list = {
          max_items = 20,
          selection = {
            preselect = false,
            auto_insert = false
          }
        },

        -- Trigger Settings
        trigger = {
          prefetch_on_insert = false,
        },

        -- Menu Display Configuration
        menu = {
          draw = {
            treesitter = { 'lsp' },
            columns = {
              { "label",      "label_description", gap = 1 },
              { "kind_icon",  "kind",              gap = 1 },
              { "source_name" }
            }
          },
        },
      },
    },

    -- Allow extending sources elsewhere in config
    opts_extend = { "sources.default" }
  }
}
