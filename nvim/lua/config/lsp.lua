-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- Enable LSP logging at info level
vim.lsp.log.set_level("error")

-- Set the LSP log file path
local log_path = vim.fn.stdpath('cache') .. '/lsp.log'
vim.fn.setenv('NVIM_LSP_LOG_FILE', log_path)

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

vim.api.nvim_create_user_command("LspInfo", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local buf_clients = vim.lsp.get_clients({ bufnr = bufnr })
  local all_clients = vim.lsp.get_clients()

  local lines = {}
  table.insert(lines, "Buffer: " .. vim.api.nvim_buf_get_name(bufnr))
  table.insert(lines, "Filetype: " .. ft)
  table.insert(lines, "")
  table.insert(lines, "Clients attached to buffer (" .. #buf_clients .. "):")
  for _, c in ipairs(buf_clients) do
    table.insert(lines, "  - " .. c.name .. " (id=" .. c.id .. ")")
    table.insert(lines, "      root:    " .. (c.config.root_dir or "n/a"))
    table.insert(lines, "      cmd:     " .. table.concat(c.config.cmd or {}, " "))
    table.insert(lines, "      filetypes: " .. table.concat(c.config.filetypes or {}, ", "))
  end
  table.insert(lines, "")
  table.insert(lines, "All active clients (" .. #all_clients .. "):")
  for _, c in ipairs(all_clients) do
    local bufs = {}
    for b, _ in pairs(c.attached_buffers) do table.insert(bufs, b) end
    table.insert(lines, "  - " .. c.name .. " (id=" .. c.id .. ", bufs=" .. table.concat(bufs, ",") .. ")")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "lspinfo"
  local width = math.min(120, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
end, { desc = "Show LSP client info for current buffer" })

vim.api.nvim_create_user_command("LspRestart", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    vim.notify("No LSP clients attached to buffer", vim.log.levels.WARN)
    return
  end
  local names = {}
  for _, c in ipairs(clients) do
    table.insert(names, c.name)
    vim.lsp.stop_client(c.id, true)
  end
  vim.defer_fn(function()
    vim.cmd.edit()
    vim.notify("Restarted: " .. table.concat(names, ", "))
  end, 200)
end, { desc = "Restart LSP clients attached to current buffer" })

local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end
