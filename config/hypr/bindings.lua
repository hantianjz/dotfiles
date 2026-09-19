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
  "SUPER + Q",
}) do
  hl.unbind(keys)
end

o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + SHIFT + F", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + SHIFT + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", { omarchy = "browser --private" })
o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian -disable-gpu --enable-wayland-ime", focus = "^obsidian$" })
o.bind("SUPER + CTRL + D", "Omarchy Menu", "omarchy-menu toggle root")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
