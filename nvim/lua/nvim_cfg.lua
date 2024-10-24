vim.g.mapleader = ';'

local o = vim.o
local w = vim.wo

o.autoread = true -- reload files when changed on disk, i.e. via `git checkout`
o.encoding = "UTF-8"
o.laststatus = 2  -- always show statusline
o.list = true
-- o.listchars = [[tab:▸ ,extends:❯,precedes:❮,nbsp:±,trail:▫]]
o.listchars = [[tab:▸ ,extends:❯,precedes:❮,nbsp:±]]

o.clipboard = [[unnamed,unnamedplus]] -- yank and paste with the system clipboard

-- Indenting
o.autoindent = true
o.smartindent = true -- Smart auto-indent

-- Tabbing
o.shiftwidth = 2   -- normal mode indentation commands use 4 spaces
o.expandtab = true -- expand tabs to spaces
o.softtabstop = 2  -- insert mode tab and backspace use 4 spaces
o.tabstop = 2      -- actual tabs occupy 8 characters

-- Search
o.ignorecase = true -- case-insensitive search
o.incsearch = true  -- search as you type
o.smartcase = true  -- case-sensitive search if any caps

-- UI
w.number = true         -- show line numbers
o.relativenumber = true -- show relative line numbers
o.ruler = true          -- show where you are
w.scrolloff = 5         -- show context above/below cursorline
o.showcmd = true
o.timeoutlen = 1000
o.ttimeoutlen = 0
w.cursorline = true
w.cursorcolumn = true

-- Enable basic mouse behavior such as resizing buffers.
o.mouse = 'a'

-- keep a copy of last edit
-- if this throws errors, make sure the backup dir exists
o.backup = true
o.backupdir = vim.env.HOME .. "/.vim/backup/"
o.backupcopy = "auto" -- see :help crontab
w.spell = true
o.updatetime = 500

vim.g.syntax_on = true

local utils = require('utils')

utils.map('n', '<leader>x', [[:%! xxd<cr>]], { noremap = true })
utils.map('n', '<leader>X', [[:%! xxd -r<cr>]], { noremap = true })
utils.map('n', '<leader><leader>', [[<C-^>]], { noremap = true })

utils.create_augroup({
  { 'VimResized', '*', [[:wincmd =]] },
}, 'WinResize')

utils.create_augroup({
  { 'BufRead,BufNewFile', '*.def',    'set',      'filetype=c' },
  { 'BufRead,BufNewFile', '*.ino',    'set',      'filetype=c' },
  { 'BufRead,BufNewFile', '*.i',      'set',      'filetype=c' },
  { 'BufRead,BufNewFile', '*.groovy', 'set',      'filetype=java' },
  { 'FileType',           'help',     'setlocal', 'nospell' },
}, 'FileTypes')

-- Setup mapping to source local file
utils.map("n", '<Leader><Leader>r', [[:source %<cr>]])
utils.map("n", '<Leader><Leader>i', [[:Inspect!<cr>]])
utils.map("n", '<Leader><Leader>t', [[<Plug>PlenaryTestFile]])
utils.map("n", '<Leader>h', [[:ClangdSwitchSourceHeader<cr>]])

-- Inspect a lua object
P = function(v)
  print(vim.inspect(v))
  return v
end
