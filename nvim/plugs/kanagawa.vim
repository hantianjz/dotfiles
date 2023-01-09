Plug 'rebelot/kanagawa.nvim'


function KanagawaSetup()
colorscheme kanagawa
endfunction

augroup KanagawaSetup
    autocmd!
    autocmd User PlugLoaded call KanagawaSetup()
augroup END
