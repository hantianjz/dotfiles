return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  cmd = "ConformInfo",
  lazy = false,
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ formatters = { "injected" }, lsp_fallback = true, timeout_ms = 3000 })
      end,
      mode = { "n", "v" },
      desc = "Format Injected Langs",
    },
  },
  opt = {
    formatters_by_ft = {
      lua = { "stylua" },
      c = { "clang-format" },
      python = { "black" },
      sh = { "shfmt" },
      gn = { "gn" },
      zig = { "zigfmt" },
      rust = { "rustfmt" },
      typescript = { "prettier" },
    }
  }
}
