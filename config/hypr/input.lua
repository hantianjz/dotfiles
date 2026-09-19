hl.config({
  input = {
    kb_layout = "us",
    -- Caps Lock is Control; swap Alt and Super.
    kb_options = "ctrl:nocaps,altwin:swap_alt_win",
    repeat_rate = 40,
    repeat_delay = 600,
    numlock_by_default = true,
    sensitivity = 0.35,
    touchpad = { scroll_factor = 0.1 },
  },
})

o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
