return {
  {
    "nvim-treesitter/nvim-treesitter",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    lazy = false,
    opts_extend = { "ensure_installed" },
    opts = {
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
    }
  }
}
