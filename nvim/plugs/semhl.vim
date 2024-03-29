Plug 'hantianjz/semhl.nvim'

function SemhlSetup()
lua << EOF
require("semhl").setup({ "c", "cpp", "h", "python", "lua" })
EOF
endfunction

augroup SemhlSetup
    autocmd!
    autocmd User PlugLoaded call SemhlSetup()
augroup END
