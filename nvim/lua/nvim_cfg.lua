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

vim.keymap.set('n', '<leader>x', [[:%! xxd<cr>]], { noremap = true })
vim.keymap.set('n', '<leader>X', [[:%! xxd -r<cr>]], { noremap = true })
vim.keymap.set('n', '<leader><leader>', [[<C-^>]], { noremap = true })
vim.keymap.set('n', '<leader>w', vim.diagnostic.open_float)


-- Setup mapping to source local file
vim.keymap.set("n", '<Leader><Leader>r', [[:source %<cr>]])
vim.keymap.set("n", '<Leader><Leader>i', [[:Inspect!<cr>]])
vim.keymap.set("n", '<Leader><Leader>t', [[<Plug>PlenaryTestFile]])
vim.keymap.set("n", '<Leader>h', [[:ClangdSwitchSourceHeader<cr>]])

-- Inspect a lua object
P = function(v)
  print(vim.inspect(v))
  return v
end

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})


vim.api.nvim_create_autocmd({ 'CursorHoldI' }, {
  pattern = '*',
  callback = function()
    if vim.bo.filetype ~= 'TelescopePrompt' and vim.bo.filetype ~= 'gitcommit' then
      vim.lsp.buf.signature_help()
    end
  end
})
