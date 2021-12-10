Plug 'kyazdani42/nvim-web-devicons'

function WebDeviconsSetup()
lua << EOF
require'nvim-web-devicons'.setup {
 default = true;
}
EOF
endfunction

augroup WebDeviconsSetup
    autocmd!
    autocmd User PlugLoadedLast call WebDeviconsSetup()
augroup END
