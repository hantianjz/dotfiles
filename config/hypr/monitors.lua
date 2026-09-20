-- Keep these names editable by Omarchy's monitor-scaling helper.
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- External monitor above the laptop panel.
-- Coordinates are logical pixels: DP-2 is 1920x1080@1x, eDP-1 is 2560x1440@1.25x = 2048x1152.
-- X=64 centers the external monitor over the laptop's wider logical width.
hl.monitor({ output = "DP-2", mode = "preferred", position = "64x0", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x1080", scale = 1.25 })
