-- Remove defaults before installing personal actions, including Display on Ctrl+D.
for _, keys in ipairs({
  "SUPER + SPACE",
  "SUPER + ALT + SPACE",
  "SUPER + K",
  "SUPER + W",
  "SUPER + RETURN",
  "SUPER + SHIFT + F",
  "SUPER + SHIFT + B",
  "SUPER + SHIFT + ALT + B",
  "SUPER + SHIFT + T",
  "SUPER + SHIFT + O",
  "SUPER + CTRL + D",
  "SUPER + CTRL + H",
  "SUPER + CTRL + K",
  "SUPER + CTRL + L",
  "SUPER + CTRL + TAB",
  "SUPER + Q",
}) do
  hl.unbind(keys)
end

for workspace = 1, 9 do
  hl.unbind("SUPER + CTRL + code:" .. tostring(workspace + 9))
end

o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + SHIFT + F", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + SHIFT + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", { omarchy = "browser --private" })
o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian -disable-gpu --enable-wayland-ime", focus = "^obsidian$" })
o.bind("SUPER + CTRL + D", "Omarchy Menu", "omarchy-menu toggle root")
o.bind("SUPER + D", "Apps menu", "omarchy-menu toggle apps")
local aerospace_directions = {
  { key = "H", direction = "l", label = "left" },
  { key = "J", direction = "d", label = "down" },
  { key = "K", direction = "u", label = "up" },
  { key = "L", direction = "r", label = "right" },
}

for _, direction in ipairs(aerospace_directions) do
  o.bind("SUPER + SHIFT + " .. direction.key, "Focus " .. direction.label .. " window", hl.dsp.focus({ direction = direction.direction }))
  o.bind("SUPER + CTRL + " .. direction.key, "Move window " .. direction.label, hl.dsp.window.swap({ direction = direction.direction }))
end

for workspace = 1, 9 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + CTRL + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

o.bind("SUPER + CTRL + TAB", "Move workspace to next monitor", hl.dsp.workspace.move({ monitor = "+1" }))

o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
