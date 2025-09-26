-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- Enable LSP logging at info level
vim.lsp.set_log_level("error")

-- Set the LSP log file path
local log_path = vim.fn.stdpath('cache') .. '/lsp.log'
vim.fn.setenv('NVIM_LSP_LOG_FILE', log_path)
print("LSP logs will be written to: " .. log_path)

local diag_float_config = {
  scope = "cursor",
  header = false,
  border = 'rounded',
  focusable = false,
}

-- lsp
vim.diagnostic.config({
  virtual_text = true,
  float = diag_float_config
})

local border = {
  { "🭽", "FloatBorder" },
  { "▔", "FloatBorder" },
  { "🭾", "FloatBorder" },
  { "▕", "FloatBorder" },
  { "🭿", "FloatBorder" },
  { "▁", "FloatBorder" },
  { "🭼", "FloatBorder" },
  { "▏", "FloatBorder" },
}

local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end
