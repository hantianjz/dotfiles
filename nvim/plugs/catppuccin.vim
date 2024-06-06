Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

function CatppuccinSetup()
colorscheme catppuccin-mocha " catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
lua << EOF
require("catppuccin").setup({
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        telescope = {
          enabled = true,
        },
        mini = {
            enabled = true,
            indentscope_color = "",
        },
    }
})
EOF
endfunction

augroup CatppuccinSetup
    autocmd!
    autocmd User PlugLoadedLast call CatppuccinSetup()
augroup END
