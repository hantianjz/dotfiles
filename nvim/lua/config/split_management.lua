local M = {}

function M.setup()
  -- Move the current vertical split to horizontal
  vim.api.nvim_set_keymap('n', '<leader>wv', ':wincmd H<CR>', { noremap = true, silent = true })
  -- Move the current horizontal split to vertical
  vim.api.nvim_set_keymap('n', '<leader>wh', ':wincmd K<CR>', { noremap = true, silent = true })
end

return M
