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
      yaml = { "yamlfmt" },
      ["*"] = { "trim_whitespace" },
    },
    formatters = {
      black = {
        prepend_args = { "--fast" },
      },
      shfmt = {
        prepend_args = { "-i", "2" }
      }
    },
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end

      -- Disable auto write on format for thse filetypes
      for _, value in ipairs({ "yaml" }) do
        if value == vim.bo[bufnr].filetype then
          return
        end
      end
      return { timeout_ms = 500, lsp_format = "fallback" }
    end,

    default_format_opts = {
      lsp_format = "fallback",
    },
    quiet = false,
    notify_on_error = true,
  },
  config = function(_, opts)
    -- Use mason to install formatters
    local formatters = { "clang-format", "black", "shfmt", "prettier", "mdformat", "djlint", "yamlfmt" }
    local formatters_to_install = {}
    for _, formatter in pairs(formatters) do
      if not require("mason-registry").is_installed(formatter) then
        table.insert(formatters_to_install, formatter)
      end
    end
    if formatters_to_install and next(formatters_to_install) then
      require("mason.api.command").MasonInstall(formatters_to_install)
    end

    -- Specify where the formatter cmd is for each formatter that we had installed from mason
    for _, formatter in pairs(formatters) do
      local mason_bin_dir = vim.fn.stdpath("data") .. "/mason/bin"
      local cmd = require("conform.util").find_executable({
        mason_bin_dir .. "//" .. formatter
      }, formatter)
      opts.formatters[formatter] = opts.formatters[formatter] or {}
      opts.formatters[formatter].command = cmd
    end

    require("conform").setup(opts)

    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, {
      desc = "Disable autoformat-on-save",
      bang = true,
    })
    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = "Re-enable autoformat-on-save",
    })
  end
}
