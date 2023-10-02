-- Inspect a lua object
P = function(v)
  print(vim.inspect(v))
  return v
end

-- Setup mapping to source local file
vim.keymap.set("n", '<Leader><Leader>r', ':source %<cr>')
vim.keymap.set("n", '<Leader><Leader>i', ':Inspect!<cr>')
vim.keymap.set("n", '<Leader><Leader>t', '<Plug>PlenaryTestFile')
