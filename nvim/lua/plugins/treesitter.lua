return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    opts = function()
      return {
        highlight = {
          enable = false,
          disable = {},
        },

        indent = {
          enable = false,
          disable = {},
        },

        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "lua",
          "python",
          "yaml",
        },

        auto_install = true,
        sync_install = false,
      }
    end
  }
}
