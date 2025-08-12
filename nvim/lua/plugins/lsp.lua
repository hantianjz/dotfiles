return {
  -- Core LSP packages
  { 'onsails/lspkind.nvim' },
  { 'p00f/clangd_extensions.nvim' },

  -- Mason package manager
  {
    'williamboman/mason.nvim',
    build = ":MasonUpdate",
    config = function()
      require('mason').setup()
    end
  },

  -- Mason LSP configuration
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
      "Saghen/blink.cmp",
    },
    config = function()
      local mason_lspconfig = require('mason-lspconfig')
      local util = require("lspconfig/util")
      local caps = require('blink.cmp').get_lsp_capabilities()

      -- List of LSP servers to install and configure
      local ensure_installed = {
        'bashls',
        'clangd',
        'jsonls',
        'lua_ls',
        'rust_analyzer',
        'mesonlsp',
        'gopls',
        -- 'typos-lsp'
      }

      -- Basic Mason setup
      mason_lspconfig.setup {
        ensure_installed = ensure_installed,
        automatic_enable = true,
      }

      ---Default on_attach function for LSP configuration
      ---@param _ any Client
      ---@param bufnr number Buffer number
      local function on_attach(_, bufnr)
        vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

        -- Mappings
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set('n', '<leader>R', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>e', vim.lsp.buf.signature_help, opts)
      end

      vim.lsp.config('copilot', {})
      vim.lsp.config('gopls', { on_attach = on_attach })
      vim.lsp.config('jdtls', { on_attach = on_attach })
      vim.lsp.config('ruff', { on_attach = on_attach })
      vim.lsp.config('ts_ls', { on_attach = on_attach })
      vim.lsp.config('ocamllsp', { on_attach = on_attach })
      vim.lsp.config('clangd',
        {
          root_markers = { ".git" },
          capabilities = caps,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          filetypes = { "c", "cpp", "proto" },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          on_attach = on_attach,
          single_file_support = true,
          handlers = {
            ['textDocument/publishDiagnostics'] = vim.lsp.with(
              vim.lsp.diagnostic.on_publish_diagnostics, {
                signs = true,
                underline = true,
                update_in_insert = false,
                virtual_text = false,
              }
            ),
          }
        })

      vim.lsp.config('lua_ls', {
        on_attach = on_attach,
        settings = {
          Lua = {
            format = {
              enable = true,
              defaultConfig = {
                indent_style = "space",
                indent_size = "2",
              },
            },
            runtime = {
              version = 'LuaJIT'
            },
            workspace = {
              checkThirdParty = true,
              library = {
                vim.env.VIMRUNTIME
              }
            },
          }
        }
      })

      vim.lsp.config('pyright', {
        on_attach = on_attach,
        root_markers = { "pyrightconfig.json", ".git" },
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = 'workspace', -- Options: 'openFilesOnly', 'workspace', or 'off'
              useLibraryCodeForTypes = true,
            }
          }
        }
      })

      vim.lsp.config('rust_analyzer', {
        on_attach = on_attach,
        settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
              extraArgs = { "--release", "--", "-D", "warning" },
            },
            diagnostics = {
              enable = true,
            }
          },
        },
      })

      vim.lsp.config('mesonlsp', {
        on_attach = on_attach,
        root_dir = util.root_pattern('meson_options.txt', 'meson.options', '.git'),
      })
    end
  },
}
