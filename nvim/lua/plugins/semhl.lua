return {
  'hantianjz/semhl.nvim',
  lazy    = false,
  enabled = false,
  opts    = {
    filetypes = { "c", "cpp", "h", "python", "lua", "typescript", "java" },
    max_file_size = 100 * 1024 -- 100 KB
  }
}
