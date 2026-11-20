-- Rex has no bulk reset. Clear the documented Mac shortcuts outside copy mode.
-- https://www.superlogical.com/rex/docs/reference/mac-actions
for _, key in ipairs({
  "cmd+n", "shift+cmd+w", "ctrl+cmd+f", "cmd+w",
  "shift+cmd+p", "cmd+,", "shift+cmd+,", "shift+cmd+u", "alt+shift+cmd+u", "shift+cmd+.",
  "shift+cmd+n", "alt+shift+cmd+n", "cmd+k", "cmd+r",
  "cmd+t", "alt+cmd+w", "ctrl+tab", "shift+cmd+]", "ctrl+shift+tab", "shift+cmd+[", "cmd+'",
  "ctrl+shift+pageup", "ctrl+shift+pagedown",
  "shift+cmd+left", "cmd+d", "shift+cmd+right", "shift+cmd+up", "shift+cmd+d", "shift+cmd+down",
  "cmd+enter", "alt+cmd+left", "alt+cmd+right", "alt+cmd+up", "alt+cmd+down",
  "cmd+]", "cmd+[", "cmd+;", "alt+shift+cmd+left", "alt+shift+cmd+right",
  "alt+shift+cmd+up", "alt+shift+cmd+down", "alt+cmd+enter", "alt+cmd+m", "alt+shift+cmd+enter",
  "shift+cmd+enter", "shift+cmd+g", "cmd+p", "ctrl+cmd+i", "shift+cmd+c",
  "cmd+backspace", "cmd+left", "cmd+right", "alt+left", "alt+right", "cmd+up", "cmd+down", "cmd+y",
  "cmd+f", "cmd+g", "shift+cmd+=", "cmd+=", "cmd+-", "cmd+/", "cmd+.", "shift+cmd+s",
  "alt+cmd+t", "alt+shift+cmd+t",
}) do
  rex.unbind(key)
end
for digit = 0, 9 do
  rex.unbind("cmd+[Digit" .. digit .. "]")
end

-- Use the tmux prefix for pane and tab navigation.
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+a>h", "pane.focus.left")
rex.bind("ctrl+a>j", "pane.focus.down")
rex.bind("ctrl+a>k", "pane.focus.up")
rex.bind("ctrl+a>l", "pane.focus.right")
rex.bind("ctrl+a>a", "pane.focus_recent.in_tab")
rex.bind("ctrl+a>ctrl+v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>ctrl+s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>shift+c", "client.tab.new")
rex.bind("ctrl+a>p", "client.tab.previous")
rex.bind("ctrl+a>n", "client.tab.next")
rex.bind("ctrl+a>shift+z", "pane.zoom")
rex.bind("cmd+w", "pane.close")
rex.bind("alt+cmd+w", "client.tab.close")
