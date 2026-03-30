---@mod plugins.treesitter Treesitter configuration
---
--- Configures nvim-treesitter for syntax highlighting and code parsing.
--- Includes automatic installation of parsers for commonly used languages.

---@type LazySpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require('nvim-treesitter').setup {
        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "lua",
          "python",
          "yaml",
          "typescript",
          "java",
          "markdown",
          "markdown_inline",
        },
        auto_install = true,
      }
    end
  }
}
