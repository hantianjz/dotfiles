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
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = {
          'bashls',
          'clangd',
          'jsonls',
          'pyright',
          'vimls',
          'lua_ls',
          'ts_ls'
        }
      }
      local caps = require('cmp_nvim_lsp').default_capabilities()
      local util = require("lspconfig/util")

      require 'mason-lspconfig'.setup_handlers {
        function(server_name) -- default handler (optional)
          require 'lspconfig'[server_name].setup { capabilities = caps }
        end,

        ['clangd'] = function()
          require 'lspconfig'.clangd.setup {
            root_dir = function(...)
              return util.root_pattern('.git')(...)
            end,
            capabilities = caps,
            cmd = { "clangd" },
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

        ["vimls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.vimls.setup {}
        end,

        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup {
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
        end
      }
    end
  },
}
