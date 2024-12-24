return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  cmd = "ConformInfo",
  lazy = false,
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ lsp_fallback = true, timeout_ms = 1000, })
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
      -- gn = {
      --   prepend_args = { "format", "--stdin" }
      -- },
      shfmt = {
        prepend_args = { "-i", "2" }
      }
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    quiet = false,
    notify_on_error = true,
  },
}
