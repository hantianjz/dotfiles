Plug 'ludovicchabant/vim-gutentags'
Plug 'skywind3000/gutentags_plus'

let g:gutentags_exclude_filetypes = ['gitcommit', 'python', 'gitrebase', 'diff', 'zsh', 'sh', 'conf', 'markdown', 'vim']
let g:gutentags_generate_on_write = 1
let g:gutentags_modules = ['ctags', 'gtags_cscope']
let g:gutentags_project_root = ['.gn', '.git']
let g:gutentags_plus_switch = 1
let g:gutentags_plus_nomap = 1
let g:gutentags_define_advanced_commands = 0

noremap <silent> <leader>gs :GscopeFind s <C-R><C-W><cr>
noremap <silent> <leader>gd :GscopeFind g <C-R><C-W><cr>
noremap <silent> <leader>gf :GscopeFind c <C-R><C-W><cr>
noremap <silent> <leader>gi :GscopeFind i <C-R><C-W><cr>
noremap <silent> <leader>ga :GscopeFind a <C-R><C-W><cr>
