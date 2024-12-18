return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  cmd = "ConformInfo",
  lazy = false,
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ formatters = { "injected" }, lsp_fallback = true, timeout_ms = 1000, })
      end,
      mode = { "n", "v" },
      desc = "Format Injected Langs",
    },
  },
  opts = {
    formatters_by_ft = {
      c = { "clang-format" },
      python = { "isort", "black" },
      sh = { "shfmt" },
      gn = { "gn" },
      zig = { "zigfmt" },
      rust = { "rustfmt" },
      typescript = { "prettier" },
      ["*"] = { "codespell", "trim_whitespace" },
    },
    formatters = {
      black = {
        prepend_args = { "--fast" },
      },
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
  },
}
