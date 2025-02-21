return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require 'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
          disable = {},
        },

        indent = {
          enable = true,
          disable = {},
        },

        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "lua",
          "python",
          "yaml",
          "typescript",
          "java"
        },

        auto_install = true,
        sync_install = true,
      }
    end
  }
}
