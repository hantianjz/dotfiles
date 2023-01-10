Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'ray-x/cmp-treesitter'


function TreesitterSetup()
lua <<EOF
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = false,
    disable = {},
  },

  indent = {
    enable = false,
    disable = {},
  },

  ensure_installed = {
    "bash",
    "c",
    "cpp",
    "lua",
    "python",
    "yaml",
  },

  auto_install = true,
}

EOF
endfunction

augroup TreesitterSetup
    autocmd!
    autocmd User PlugLoaded call TreesitterSetup()
augroup END
