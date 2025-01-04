return {
  { 'neovim/nvim-lspconfig' },
  { 'onsails/lspkind.nvim' },
  { 'p00f/clangd_extensions.nvim' },
  { 'pappasam/jedi-language-server' },
  {
    'williamboman/mason.nvim',
    build = ":MasonUpdate",
    config = function()
      require('mason').setup()
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {
      "Saghen/blink.cmp",
    },
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = {
          'bashls',
          'clangd',
          'jsonls',
          'pyright',
          'lua_ls',
          'ts_ls',
          'ocamllsp',
          "jdtls",
          "typos_lsp",
          "harper_ls",
        }
      }
      local caps = require('blink.cmp').get_lsp_capabilities()
      local util = require("lspconfig/util")

      local on_attach = function(_, bufnr)
        vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

        -- Mappings.
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set('n', '<leader>R', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, opts)
      end

      require 'mason-lspconfig'.setup_handlers {
        function(server_name) -- default handler (optional)
          require 'lspconfig'[server_name].setup { capabilities = caps }
        end,

        ['jdtls'] = function()
          require 'lspconfig'.jdtls.setup {
            on_attach = on_attach,
          }
        end,

        ['clangd'] = function()
          require 'lspconfig'.clangd.setup {
            root_dir = function(...)
              return util.root_pattern('.git')(...)
            end,
            capabilities = caps,
            cmd = { "clangd",
              "--background-index",
              "--clang-tidy",
              "--header-insertion=iwyu",
              "--completion-style=detailed",
              "--function-arg-placeholders",
              "--fallback-style=llvm",
            },
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
          }
        end,

        ['pyright'] = function()
          require 'lspconfig'.pyright.setup {
            root_dir = function(...)
              return util.root_pattern('.git')(...)
            end,
            on_attach = on_attach,
            settings = {
              pyright = {
                autoImportCompletion = true,
              },
              python = {
                analysis = {
                  autoSearchPaths = true,
                  diagnosticMode = 'openFilesOnly',
                  useLibraryCodeForTypes = true,
                  typeCheckingMode = 'off'
                }
              }
            }
          }
        end,

        ["ts_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.ts_ls.setup {
            on_attach = on_attach,
          }
        end,

        ["ocamllsp"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.ocamllsp.setup {
            on_attach = on_attach,
          }
        end,

        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup {
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
                  checkThirdParty = false,
                  library = {
                    vim.env.VIMRUNTIME
                  }
                },
              }
            }
          }
        end,

        ["typos_lsp"] = function()
          require('lspconfig').typos_lsp.setup({})
        end,

        ["harper_ls"] = function()
          require 'lspconfig'.harper_ls.setup({
          })
        end,
      }
    end
  },
}
