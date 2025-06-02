---@mod plugins.conform Code formatting configuration
---
--- Configures conform.nvim for code formatting with multiple formatters
--- and format-on-save functionality. Includes automatic formatter installation
--- through Mason.

---@type LazySpec
return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  cmd = "ConformInfo",
  lazy = false,

  -- Keybindings
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({
          lsp_format = "first",
          timeout_ms = 1000
        })
      end,
      mode = { "n", "v" },
      desc = "Format current file",
    },
  },

  opts = {
    -- Formatter configurations by filetype
    formatters_by_ft = {
      -- Systems Programming
      c = { "clang-format", lsp_format = "first" },
      rust = { "rustfmt", lsp_format = "first" },

      -- Scripting Languages
      python = { "isort", "black" },
      sh = { "shfmt" },

      -- Build Systems
      gn = { "gn" },
      zig = { "zigfmt" },

      -- Web Technologies
      typescript = { "prettier" },
      html = { "djlint" },

      -- Configuration Files
      yaml = { "yamlfmt" },
      toml = { "taplo" },

      -- Global Formatters
      ["*"] = { "trim_whitespace" },
    },

    -- Formatter-specific configurations
    formatters = {
      black = {
        prepend_args = { "--fast", "--line-length", "120" },
      },
      shfmt = {
        prepend_args = { "-i", "2" }
      }
    },

    -- Format on save configuration
    format_on_save = function(bufnr)
      -- Check for global or buffer-local disable flags
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end

      -- Disable auto format for specific filetypes
      local disabled_filetypes = { "yaml", "dts" }
      for _, ft in ipairs(disabled_filetypes) do
        if ft == vim.bo[bufnr].filetype then
          return
        end
      end

      return {
        timeout_ms = 500,
        lsp_format = "first"
      }
    end,

    -- General options
    default_format_opts = {
      timeout_ms = 500,
      lsp_format = "first",
    },
    quiet = false,
    notify_on_error = true,
  },

  config = function(_, opts)
    -- Disable format on write by default
    vim.g.disable_autoformat = true

    -- Define formatters to install via Mason
    local formatters = {
      "clang-format",
      "black",
      "shfmt",
      "prettier",
      "mdformat",
      "djlint",
      "yamlfmt"
    }

    -- Install missing formatters
    local formatters_to_install = {}
    for _, formatter in pairs(formatters) do
      if not require("mason-registry").is_installed(formatter) then
        table.insert(formatters_to_install, formatter)
      end
    end

    if formatters_to_install and next(formatters_to_install) then
      require("mason.api.command").MasonInstall(formatters_to_install)
    end

    -- Configure formatter paths from Mason
    local mason_bin_dir = vim.fn.stdpath("data") .. "/mason/bin"
    for _, formatter in pairs(formatters) do
      local cmd = require("conform.util").find_executable({
        mason_bin_dir .. "//" .. formatter
      }, formatter)
      opts.formatters[formatter] = opts.formatters[formatter] or {}
      opts.formatters[formatter].command = cmd
    end

    -- Setup conform with options
    require("conform").setup(opts)

    -- Create user commands for enabling/disabling format-on-save
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        -- FormatDisable! disables formatting for current buffer only
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
