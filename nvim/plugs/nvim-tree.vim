Plug 'kyazdani42/nvim-tree.lua'

function NvimTreeSetup()
lua <<EOF
require'nvim-tree'.setup{
  view = {
    width = 40,
    preserve_window_proportions = true
  },
}

EOF
endfunction

augroup NvimTreeSetup
    autocmd!
    autocmd User PlugLoaded call NvimTreeSetup()
augroup END
