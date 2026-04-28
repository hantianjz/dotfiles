return {
  -- dir = "~/Development/hjz/semhl.nvim", -- 👈 use local path instead of repo
  "hantianjz/semhl.nvim",
  name = "semhl.nvim", -- optional but recommended
  enabled = true,
  ft = { "c", "cpp", "h", "python", "lua", "typescript", "java", "rust", "go" },
  opts = {
    source = "lsp",
    filetypes = { "c", "cpp", "h", "python", "lua", "typescript", "java", "rust", "go" },
    max_file_size = 100 * 1024,
    target_delta_e = 30,
    disable = function(buffer)
      if vim.api.nvim_buf_get_name(buffer):match("^octo://") then
        return true
      end
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buffer))
      if ok and stats and stats.size > 100 * 1024 then
        return true
      end
      return false
    end,
  },
}
