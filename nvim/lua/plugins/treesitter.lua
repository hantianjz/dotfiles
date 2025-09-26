---@mod plugins.treesitter Treesitter configuration
---
--- Configures nvim-treesitter for syntax highlighting and code parsing.
--- Includes automatic installation of parsers for commonly used languages.

---@type LazySpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require('nvim-treesitter.configs').setup {
        -- Syntax Highlighting
        highlight = {
          enable = false,
          disable = {},
        },

        -- Indentation
        indent = {
          enable = true,
          disable = {},
        },

        -- Language Parser Installation
        ensure_installed = {
          -- Shell
          "bash",

          -- Systems Programming
          "c",
          "cpp",

          -- Scripting
          "lua",
          "python",

          -- Web & Config
          "yaml",
          "typescript",

          -- JVM
          "java"
        },

        -- Installation Settings
        auto_install = true, -- Automatically install missing parsers
        sync_install = true, -- Install parsers synchronously
      }
    end
  }
}

