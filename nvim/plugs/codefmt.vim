Plug 'google/vim-codefmt'
Plug 'google/vim-maktaba'

nnoremap <leader>f :FormatCode<CR>

augroup autoformat_settings
  autocmd FileType python AutoFormatBuffer black
augroup END
