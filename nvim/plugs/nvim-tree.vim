Plug 'kyazdani42/nvim-tree.lua'

function NvimTreeSetup()
lua <<EOF

require'nvim-tree'.setup{
  filters = {
    dotfiles = true,
  },
}

EOF
endfunction

augroup NvimTreeSetup
    autocmd!
    autocmd User PlugLoaded call NvimTreeSetup()
augroup END
