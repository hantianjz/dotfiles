"--------------------------------------------------------------------------
" General settings
"--------------------------------------------------------------------------

set autoread                                                 " reload files when changed on disk, i.e. via `git checkout`
set backspace=2                                              " Fix broken backspace in some setups
set clipboard=unnamed,unnamedplus                            " yank and paste with the system clipboard
set encoding=UTF-8
set laststatus=2                                             " always show statusline
set list                                                     " show trailing whitespace
set listchars=tab:▸\ ,trail:▫

" Indenting
set autoindent
set smartindent                                              " Smart auto-indent

" Tabbing
set shiftwidth=2                                             " normal mode indentation commands use 4 spaces
set expandtab                                                " expand tabs to spaces
set softtabstop=2                                            " insert mode tab and backspace use 4 spaces
set tabstop=2                                                " actual tabs occupy 8 characters

" Search
set ignorecase                                               " case-insensitive search
set incsearch                                                " search as you type
set nohlsearch                                               " Disable seach highlight
set smartcase                                                " case-sensitive search if any caps

" UI
set number                                                   " show line numbers
set relativenumber                                           " show relative line numbers
set ruler                                                    " show where you are
set scrolloff=5                                              " show context above/below cursorline
set showcmd
set timeoutlen=1000 ttimeoutlen=0
set cursorline
set cursorcolumn

" Enable basic mouse behavior such as resizing buffers.
set mouse=a

" keep a copy of last edit
" if this throws errors, make sure the backup dir exists
set backup
set backupdir=~/.vim/backup/
set backupcopy=auto                                          " see :help crontab
set noswapfile
set spell
set updatetime=500

" enable syntax highlighting
syntax enable

filetype on

"--------------------------------------------------------------------------
" Key maps
"--------------------------------------------------------------------------

let mapleader = ';' " The LEADER KEY

" Clean white space
nnoremap <leader><space> :call whitespace#strip_trailing()<CR>

" in case you forgot to sudo
cnoremap w!! %!sudo tee > /dev/null %

" xxd
noremap <leader>x :%! xxd<cr>
noremap <leader>X :%! xxd -r<cr>

" Go back to previous file
nnoremap <Leader><Leader> <C-^>
"--------------------------------------------------------------------------
" Plugins
"--------------------------------------------------------------------------

" Automatically install vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(data_dir . '/plugins')

source ~/.config/nvim/plugs/buffer_bye.vim
source ~/.config/nvim/plugs/code_format.vim
source ~/.config/nvim/plugs/catppuccin.vim
source ~/.config/nvim/plugs/devicons.vim
source ~/.config/nvim/plugs/easyclip.vim
source ~/.config/nvim/plugs/gitgutter.vim
source ~/.config/nvim/plugs/gn.vim
" source ~/.config/nvim/plugs/kanagawa.vim
source ~/.config/nvim/plugs/lsp.vim
source ~/.config/nvim/plugs/lualine.vim
source ~/.config/nvim/plugs/rust.vim
source ~/.config/nvim/plugs/semhl.vim
source ~/.config/nvim/plugs/telescope.vim
source ~/.config/nvim/plugs/tmux.vim
source ~/.config/nvim/plugs/tpope.vim
source ~/.config/nvim/plugs/treesitter.vim
source ~/.config/nvim/plugs/whitespace.vim
source ~/.config/nvim/plugs/zig.vim
source ~/.config/nvim/plugs/obsidian.vim

call plug#end()
doautocmd User PlugLoaded
doautocmd User PlugLoadedLast

"--------------------------------------------------------------------------
" Miscellaneous
"--------------------------------------------------------------------------
"
" Flash highlight yanked text
au TextYankPost * lua vim.highlight.on_yank {higroup="IncSearch", timeout=150, on_visual=true}

" automatically rebalance windows on vim resize
autocmd VimResized * :wincmd =

" Hint to file type
autocmd BufRead,BufNewFile *.def set filetype=c
autocmd BufRead,BufNewFile *.ino set filetype=c
autocmd BufRead,BufNewFile *.i set filetype=c
autocmd BufRead,BufNewFile *.groovy set filetype=java
autocmd FileType help setlocal nospell

source ~/.config/nvim/globals.lua

lua <<EOF
  -- Hide all semantic highlights
  for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
    vim.api.nvim_set_hl(0, group, {})
  end
EOF
