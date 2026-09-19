local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end
local platform = dofile(root .. "/envy/platform.lua")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function contains(values, wanted)
  for _, value in ipairs(values) do
    if value == wanted then
      return true
    end
  end
  return false
end

local function find_package(values, wanted)
  for _, value in ipairs(values) do
    if value.package == wanted then
      return value
    end
  end
end

local function command_set(commands)
  return function(command)
    return commands[command] == true
  end
end

local profile, manager = platform.detect("darwin", command_set({}))
assert_equal(profile, "macos")
assert_equal(manager, "brew")

profile, manager = platform.detect("linux", command_set({ pacman = true, ["apt-get"] = true, ["dpkg-query"] = true }))
assert_equal(profile, "arch", "pacman must take precedence")
assert_equal(manager, "pacman")

profile, manager = platform.detect("linux", command_set({ ["apt-get"] = true, ["dpkg-query"] = true }))
assert_equal(profile, "ubuntu")
assert_equal(manager, "apt")

local macos = platform.packages("macos", "brew")
assert(contains(macos.packages, "lazygit"))
assert(contains(macos.packages, "herdr"))
assert(contains(macos.packages, "tuicr"))
assert(contains(macos.casks, "ghostty"))
assert(contains(macos.casks, "aerospace"))
assert(contains(macos.taps, "agavra/tap"))
assert(contains(macos.taps, "nikitabobko/tap"))
assert_equal(#macos.crates, 0)

local ubuntu = platform.packages("ubuntu", "apt")
assert(contains(ubuntu.packages, "fd-find"))
assert(contains(ubuntu.packages, "wl-clipboard"))
assert(not contains(ubuntu.packages, "ghostty"))
assert(not contains(ubuntu.packages, "lazygit"))
assert_equal(#ubuntu.crates, 7)
local yazi = assert(find_package(ubuntu.crates, "yazi-build"))
assert(yazi.force, "yazi-build must be installed with --force")
assert(not find_package(ubuntu.crates, "yazi-fm"))
assert(not find_package(ubuntu.crates, "yazi-cli"))

local arch = platform.packages("arch", "pacman")
assert(contains(arch.packages, "github-cli"))
assert(contains(arch.packages, "ghostty"))
assert(contains(arch.packages, "typos"))
assert(contains(arch.packages, "wl-clipboard"))
assert(not contains(arch.packages, "typos-cli"))
assert_equal(#arch.crates, 0)

local mac_links = platform.desktop_links("macos", "/repo", "/home/test")
assert_equal(#mac_links, 1)
assert(mac_links[1].dest:match("aerospace"))

local ubuntu_links = platform.desktop_links("ubuntu", "/repo", "/home/test")
assert_equal(#ubuntu_links, 0)

local arch_links = platform.desktop_links("arch", root, "/home/test")
local expected_destinations = {}
for _, filename in ipairs({
  "autostart.lua", "bindings.lua", "hyprland.lua", "hyprsunset.conf",
  "input.lua", "looknfeel.lua", "monitors.lua", "xdph.conf",
}) do
  expected_destinations["/home/test/.config/hypr/" .. filename] = true
end
local seen = {}
for _, link in ipairs(arch_links) do
  assert(expected_destinations[link.dest], "unexpected managed destination: " .. link.dest)
  assert(not seen[link.dest], "duplicate managed destination: " .. link.dest)
  seen[link.dest] = true
  local source = assert(io.open(link.source, "r"), "missing managed source: " .. link.source)
  source:close()
end
for dest in pairs(expected_destinations) do
  assert(seen[dest], "missing managed destination: " .. dest)
end
for _, basename in ipairs({
  "autostart", "bindings", "envs", "hypridle", "hyprland",
  "hyprlock", "input", "looknfeel", "monitors",
}) do
  assert(not seen["/home/test/.config/hypr/" .. basename .. ".conf"],
    "retired destination must not be managed: " .. basename)
end

local ok = pcall(function()
  platform.detect("linux", command_set({}))
end)
assert(not ok, "unsupported Linux package managers must fail")

print("platform policy tests passed")
