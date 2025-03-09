---@mod plugins.semhl Semantic Highlighting configuration
---
--- Configures semantic highlighting for various programming languages.
--- Currently disabled but configured with file size limits and specific language support.

---@type LazySpec
return {
  'hantianjz/semhl.nvim',
  branch = "main",
  lazy = false,
  enabled = false,
  opts = {
    -- List of filetypes to enable semantic highlighting
    filetypes = {
      "c",
      "cpp",
      "h",
      "python",
      "lua",
      "typescript",
      "java"
    },
    -- Maximum file size to apply highlighting (100 KB)
    max_file_size = 100 * 1024
  }
}