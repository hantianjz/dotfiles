local M = {}

local windows = {
  left = "h",
  down = "j",
  up = "k",
  right = "l",
}

local function focus_herdr(direction)
  local pane_id = vim.env.HERDR_PANE_ID
  if not pane_id then return end

  vim.system({
    "herdr", "pane", "focus",
    "--direction", direction,
    "--pane", pane_id,
  }, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify("Could not focus Herdr pane", vim.log.levels.DEBUG)
      end)
    end
  end)
end

function M.navigate(direction)
  local window_key = windows[direction]
  if not window_key then return end

  local previous_window = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(window_key)
  if vim.api.nvim_get_current_win() == previous_window then
    focus_herdr(direction)
  end
end

function M.setup()
  for direction, key in pairs({
    left = "<C-h>",
    down = "<C-j>",
    up = "<C-k>",
    right = "<C-l>",
  }) do
    vim.keymap.set("n", key, function()
      M.navigate(direction)
    end, {
      silent = true,
      desc = "Navigate " .. direction .. " through Neovim or Herdr panes",
    })

    vim.keymap.set("t", key, function()
      vim.cmd.stopinsert()
      M.navigate(direction)
    end, {
      silent = true,
      desc = "Navigate " .. direction .. " through Neovim or Herdr panes",
    })
  end
end

return M
