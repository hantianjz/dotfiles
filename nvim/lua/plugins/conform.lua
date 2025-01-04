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
      desc = "Format current file",
    },
  },
  opts = {
    formatters_by_ft = {
      c = { "clang-format" },
      python = { "isort", "black" },
      sh = { "shfmt" },
      gn = { "gn" },
      zig = { "zigfmt" },
      typescript = { "prettier" },
      html = { "djlint" },
      ["*"] = { "codespell", "trim_whitespace" },
    },
    formatters = {
      black = {
        prepend_args = { "--fast" },
      },
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
  config = function(_, opts)
    require("conform").setup(opts)

    -- Use mason to install formatters
    local formatters = { "clang-format", "black", "shfmt", "prettier", "mdformat", "djlint" }
    local formatters_to_install = {}
    for _, formatter in pairs(formatters) do
      if not require("mason-registry").is_installed(formatter) then
        table.insert(formatters_to_install, formatter)
      end
    end
    if formatters_to_install and next(formatters_to_install) then
      require("mason.api.command").MasonInstall(formatters_to_install)
    end
  end
}
