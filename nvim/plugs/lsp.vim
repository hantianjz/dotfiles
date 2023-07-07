Plug 'L3MON4D3/LuaSnip'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-calc'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'neovim/nvim-lspconfig'
Plug 'onsails/lspkind.nvim'
Plug 'p00f/clangd_extensions.nvim'
Plug 'pappasam/jedi-language-server'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'williamboman/mason.nvim', { 'do': ':MasonUpdate' }


function LspCmpSetup()
lua <<EOF

local nvim_lsp = require('lspconfig')

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- lsp
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, { update_in_insert = false }
)

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local lspkind = require'lspkind'
local cmp = require'cmp'

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local cmp = require 'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },

  formatting = { format = lspkind.cmp_format({ mode = 'symbol' }) },

  mapping = {
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif vim.fn["vsnip#available"](1) == 1 then
          feedkey("<Plug>(vsnip-expand-or-jump)", "")
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function()
        if cmp.visible() then
          cmp.select_prev_item()
        elseif vim.fn["vsnip#jumpable"](-1) == 1 then
          feedkey("<Plug>(vsnip-jump-prev)", "")
        end
      end, { "i", "s" }),
  },

  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'treesitter' },
    { name = 'vsnip' },
    { name = 'calc' },
    { name = 'buffer' },
    { name = 'path' }
  })
})

-- Add additional capabilities supported by nvim-cmp
require('mason').setup()
require('mason-lspconfig').setup{
  ensure_installed = {
    'bashls',
    'clangd',
    'jsonls',
    'tsserver',
    'pyright',
    'vimls',
    "lua_ls"
  }
}

local caps = require('cmp_nvim_lsp').default_capabilities()
local util = require("lspconfig/util")

require'mason-lspconfig'.setup_handlers{
    function (server_name) -- default handler (optional)
        require'lspconfig'[server_name].setup{capabilities = caps}
    end,

    ['clangd'] = function()
        require'lspconfig'.clangd.setup{
          capabilities = caps,
          cmd = {"clangd"},
          single_file_support = false,
          handlers = {
            ['textDocument/publishDiagnostics'] = vim.lsp.with(
              vim.lsp.diagnostic.on_publish_diagnostics, {
                signs = true,
                underline = true,
                update_in_insert = false,
                virtual_text = true,
              }
            ),
          }
        }
      end,

    ['pyright'] = function()
        require'lspconfig'.pyright.setup{
          root_dir = function(...)
              return util.root_pattern('pyrightconfig.json')(...)
          end
        }
      end
}

vim.lsp.set_log_level("off") -- "debug" or "trace"

EOF

nmap <leader>h :ClangdSwitchSourceHeader<CR>

endfunction

augroup LspCmpSetup
    autocmd!
    autocmd User PlugLoaded call LspCmpSetup()
augroup END
