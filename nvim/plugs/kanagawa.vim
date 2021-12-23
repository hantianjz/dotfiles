Plug 'rebelot/kanagawa.nvim'


function kanagawaSetup()
colorscheme kanagawa
endfunction

augroup DuoduoSetup
    autocmd!
    autocmd User PlugLoaded call kanagawaSetup()
augroup END
