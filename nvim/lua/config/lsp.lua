-- Set completeopt to have a better completion experience
-- vim.o.completeopt = 'menuone,noselect'


vim.lsp.set_log_level("off") -- "debug" or "trace"

local diag_float_config = {
  scope = "cursor",
  header = false,
  border = 'rounded',
  focusable = false,
}

-- lsp
vim.diagnostic.config({
  virtual_text = false,
  float = diag_float_config
})

vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
  pattern = '*',
  callback = function()
    vim.diagnostic.open_float()
  end
})

vim.api.nvim_create_autocmd({ 'CursorHoldI' }, {
  pattern = '*',
  callback = function()
    if vim.bo.filetype ~= 'TelescopePrompt' and vim.bo.filetype ~= 'gitcommit' then
      vim.lsp.buf.signature_help()
    end
  end
})
