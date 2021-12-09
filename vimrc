" don't bother with vi compatibility
set nocompatible

" enable syntax highlighting
syntax enable

" configure Vundle
filetype on " without this vim emits a zero exit status, later, because of :ft off
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" install Vundle bundles
if filereadable(expand("~/.vimrc.bundles"))
    source ~/.vimrc.bundles
endif

call vundle#end()

call glaive#Install()

filetype on
" ensure ftdetect et al work by including this after the Vundle stuff
filetype plugin indent on

set autoindent
set cindent
set cino=(0
set autoread                                                 " reload files when changed on disk, i.e. via `git checkout`
set backspace=2                                              " Fix broken backspace in some setups
set backupcopy=yes                                           " see :help crontab
set clipboard+=unnamedplus                                   " yank and paste with the system clipboard
set directory-=.                                             " don't store swapfiles in the current directory
set encoding=UTF-8
set expandtab                                                " expand tabs to spaces
set ignorecase                                               " case-insensitive search
set incsearch                                                " search as you type
set laststatus=2                                             " always show statusline
set list                                                     " show trailing whitespace
set listchars=tab:▸\ ,trail:▫
set number                                                   " show line numbers
set relativenumber                                           " show relative line numbers
set ruler                                                    " show where you are
set scrolloff=3                                              " show context above/below cursorline
set shiftwidth=2                                             " normal mode indentation commands use 4 spaces
set showcmd
set smartcase                                                " case-sensitive search if any caps
set softtabstop=2                                            " insert mode tab and backspace use 4 spaces
set tabstop=2                                                " actual tabs occupy 8 characters
set wildignore=log/**,node_modules/**,target/**,tmp/**,*.rbc
set wildmenu                                                 " show a navigable menu for tab completion
set wildignore+=*/tmp/*,*.so,*.o,*.swp,*.zip
set timeoutlen=1000 ttimeoutlen=0
set nohlsearch                                               " Disable seach highlight

" Enable basic mouse behavior such as resizing buffers.
set mouse=a
" if exists('$TMUX')  " Support resizing in tmux
"   set ttymouse=xterm2
" endif

set background=dark

" keep a copy of last edit
" if this throws errors, make sure the backup dir exists
set backup
set backupdir=~/.vim/backup/

" keyboard shortcuts
let mapleader = ';'

let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
nnoremap <silent> <C-p> :TmuxNavigatePrevious<cr>

noremap <leader>l :Align
nnoremap <leader>f :FormatCode<CR>
nnoremap <leader>t :FZF<CR>
nnoremap <leader><space> :call whitespace#strip_trailing()<CR>

noremap <leader>C :SemanticHighlightToggle<CR>

" in case you forgot to sudo
cnoremap w!! %!sudo tee > /dev/null %

autocmd BufRead,BufNewFile *.def set filetype=c
autocmd BufRead,BufNewFile *.ino set filetype=c
autocmd BufRead,BufNewFile *.i set filetype=c
autocmd BufRead,BufNewFile *.groovy set filetype=java
" fdoc is yaml
autocmd BufRead,BufNewFile *.fdoc set filetype=yaml
" md is markdown
autocmd BufRead,BufNewFile *.md set filetype=markdown
autocmd BufRead,BufNewFile *.md set spell
" automatically rebalance windows on vim resize
autocmd VimResized * :wincmd =

" Fix Cursor in TMUX
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Go crazy!
if filereadable(expand("~/.vimrc.local"))
  " In your .vimrc.local, you might like:
  "
  " set autowrite
  " set nocursorline
  " set nowritebackup
  " set whichwrap+=<,>,h,l,[,] " Wrap arrow keys between lines
  "
  " autocmd! bufwritepost .vimrc source ~/.vimrc
  " noremap! jj <ESC>
  source ~/.vimrc.local
endif

colorscheme duoduo


set cursorline
set cursorcolumn
set noswapfile
set tags=tags;/


nnoremap <Leader>q :Bdelete<CR>

let g:semanticPersistCache = 1
let g:semanticUseCache = 1
let g:semanticTermColors = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]

let g:semanticEnableFileTypes = ["c", "python", "cpp", "cmake", "java", "gn", "gni", "cc", "zig"]

" FZF
set rtp+=~/.fzf/
let g:fzf_nvim_statusline = 0 " disable statusline overwriting
let g:fzf_height = 10
let g:fzf_buffers_jump = 1

" Change tabspace
function TabSpace(count)
    echom a:count
    let &softtabstop=a:count
    let &shiftwidth=a:count
    let &tabstop=a:count
endfunction

let g:airline_theme='base16_bright'

autocmd Filetype python setlocal ts=2 sw=2 expandtab

let g:gutentags_exclude_filetypes = ['gitcommit', 'python', 'gitrebase', 'diff', 'zsh', 'sh', 'conf', 'markdown']
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

noremap <leader>x :%! xxd<cr>
noremap <leader>X :%! xxd -r<cr>

au TextYankPost * lua vim.highlight.on_yank {higroup="IncSearch", timeout=150, on_visual=true}

lua <<EOF

local nvim_lsp = require('lspconfig')

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end,
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- For vsnip users.
    }, {
    { name = 'buffer'},
    { name = 'path'}
    }
  )
})

-- Add additional capabilities supported by nvim-cmp
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

nvim_lsp.ccls.setup{
  init_options = {
    index = {
      threads = 4;
    };
    clang = {
      excludeArgs = { } ;
    };
  },
  cmd = { "ccls" },
  filetypes = {"c", "cc", "cpp", "h"},
  root_dir = nvim_lsp.util.root_pattern("compile_commands.json"),
  capabilities = capabilities
}

require'lspconfig'.jedi_language_server.setup{}

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

require'nvim-web-devicons'.setup {}

EOF

nnoremap <leader>t <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>s <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>b <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>e <cmd>lua require('telescope.builtin').file_browser()<cr>
nnoremap <leader>lf <cmd>lua require('telescope.builtin').lsp_references()<cr>
nnoremap <leader>ld <cmd>lua require('telescope.builtin').lsp_definitions()<cr>
nnoremap <leader>lt <cmd>lua require('telescope.builtin').lsp_type_definitions()<cr>
nnoremap <leader>li <cmd>lua require('telescope.builtin').lsp_implementations()<cr>
