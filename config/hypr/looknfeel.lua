-- Personal appearance overrides go here; inherit Omarchy defaults.

-- Window spacing. Defaults are gaps_in = 5 and gaps_out = 10.
-- Increase these values to add space between windows / screen edges.
hl.config({
  general = {
    gaps_in = 1,
    gaps_out = 0,
  },
})

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
