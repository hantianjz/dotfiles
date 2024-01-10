Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

function CatppuccinSetup()
colorscheme catppuccin " catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
lua << EOF
EOF
endfunction

augroup CatppuccinSetup
    autocmd!
    autocmd User PlugLoadedLast call CatppuccinSetup()
augroup END
