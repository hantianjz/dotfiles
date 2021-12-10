Plug 'hantianjz/duoduo'


function DuoduoSetup()
colorscheme duoduo
endfunction

augroup DuoduoSetup
    autocmd!
    autocmd User PlugLoaded call DuoduoSetup()
augroup END
