local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      local terminal_count = 0
      for _, win in ipairs(vim.fn.getwininfo()) do
        if win.bufnr ~= -1 and vim.fn.bufname(win.bufnr):match('term://') then
          terminal_count = terminal_count + 1
        end
      end
      if terminal_count > 0 and vim.fn.confirm("You have open terminal sessions. Do you want to close them and exit?", "&Yes\n&No", 2) == 1 then
        for _, win in ipairs(vim.fn.getwininfo()) do
          if win.bufnr ~= -1 and vim.fn.bufname(win.bufnr):match('term://') then
            vim.cmd("bd! " .. win.bufnr)
          end
        end
        vim.cmd("quit")
      end
    end,
  })
end

return M
