return {
  dir = "~/Development/hjz/semhl.nvim", -- 👈 use local path instead of repo
  name = "semhl.nvim",                  -- optional but recommended
  enabled = true,
  opts = {
    filetypes = { "c", "cpp", "h", "python", "lua", "typescript", "java", "rust" },
    max_file_size = 100 * 1024,
    target_delta_e = 30,
  },
}
