Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

function TelescopeSetup()
lua << EOF
local actions = require("telescope.actions")

require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<esc>"] = actions.close,
            },
        },
    },
})
EOF

nnoremap <leader>t <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>s <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>b <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>lf <cmd>lua require('telescope.builtin').lsp_references()<cr>
nnoremap <leader>ld <cmd>lua require('telescope.builtin').lsp_definitions()<cr>
endfunction

augroup TelescopeSetup
    autocmd!
    autocmd User PlugLoaded call TelescopeSetup()
augroup END
