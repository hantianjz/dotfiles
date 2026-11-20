-- Rex has no bulk reset. Keep the default font, copy-mode, and command palette shortcuts.
-- https://www.superlogical.com/rex/docs/reference/mac-actions
for _, key in ipairs({
  "cmd+n", "shift+cmd+w", "ctrl+cmd+f",
  "shift+cmd+,", "shift+cmd+u", "alt+shift+cmd+u", "shift+cmd+.",
  "shift+cmd+n", "alt+shift+cmd+n", "cmd+r",
  "alt+cmd+w", "ctrl+tab", "shift+cmd+]", "ctrl+shift+tab", "shift+cmd+[", "cmd+'",
  "ctrl+shift+pageup", "ctrl+shift+pagedown",
  "shift+cmd+left", "cmd+d", "shift+cmd+right", "shift+cmd+up", "shift+cmd+d", "shift+cmd+down",
  "cmd+enter", "alt+cmd+left", "alt+cmd+right", "alt+cmd+up", "alt+cmd+down",
  "cmd+]", "cmd+[", "alt+shift+cmd+left", "alt+shift+cmd+right",
  "alt+shift+cmd+up", "alt+shift+cmd+down", "alt+cmd+enter", "alt+cmd+m", "alt+shift+cmd+enter",
  "shift+cmd+enter", "shift+cmd+g", "ctrl+cmd+i", "shift+cmd+c",
  "cmd+backspace", "cmd+left", "cmd+right", "alt+left", "alt+right", "cmd+up", "cmd+down", "cmd+y",
  "cmd+/", "cmd+.", "shift+cmd+s",
  "alt+cmd+t", "alt+shift+cmd+t",
}) do
  rex.unbind(key)
end
for digit = 1, 9 do
  rex.unbind("cmd+[Digit" .. digit .. "]")
end

local directions = { left = "h", down = "j", up = "k", right = "l" }
local terminal = "com.superlogical.terminal"

rex.action{
  name = "navigate_pane",
  title = "Navigate Pane or Neovim Window",
  args = { direction = "string", from_editor = "boolean?" },
  repeats = true,
  run = function(ctx, args)
    local key = assert(directions[args.direction], "Expected left, down, up, or right")
    if args.from_editor then
      -- An asynchronous edge request must not move focus from a different pane.
      local view, err = rex.session.view{}
      if not view then error(err, 0) end
      local focused
      for _, window in ipairs(view.windows) do
        if window.window_id == view.active_window_id then
          focused = window.focused_block_id
          break
        end
      end
      if not focused or focused ~= ctx.block_id then return end
    elseif ctx.block_id then
      local process = rex.block.call(terminal, "process", { block_id = ctx.block_id })
      if process and process.foreground and process.foreground.name == "nvim" then
        local _, err = rex.block.call(terminal, "write", {
          block_id = ctx.block_id,
          data = string.char(key:byte() - 96),
        })
        if err then error(err, 0) end
        return
      end
    end
    local _, err = rex.session.focus_direction{ direction = args.direction }
    if err then error(err, 0) end
  end,
}

for direction, key in pairs(directions) do
  rex.bind("ctrl+" .. key, "navigate_pane", { direction = direction })
end

-- Use the tmux prefix for other pane and tab actions.

-- Create pane splits
rex.bind("ctrl+a>ctrl+v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>ctrl+s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })

--
rex.bind("ctrl+a>shift+c", "client.tab.new")
rex.bind("ctrl+a>n", "client.tab.next")
rex.bind("ctrl+a>shift+z", "pane.zoom")
rex.bind("cmd+shift+w", "client.tab.close")

-- Match tmux session navigation.
rex.bind("ctrl+a>-", "session.previous")
rex.bind("ctrl+a>=", "session.next")

-- Copy mode already binds y to copy the selection and exit.
rex.bind("ctrl+a>[", "pane.copy_mode.enter")

rex.bind("cmd+c", "pane.copy")
rex.bind("cmd+v", "pane.paste")
