Plug 'kyazdani42/nvim-web-devicons'

function WebDeviconsSetup()
lua << EOF
require'nvim-web-devicons'.setup {}
EOF
endfunction

augroup WebDeviconsSetup
    autocmd!
    autocmd User PlugLoaded call WebDeviconsSetup()
augroup END
