local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end
local platform = dofile(root .. "/envy/platform.lua")
local profile = assert(os.getenv("TEST_PROFILE"), "TEST_PROFILE is required")
local managers = { macos = "brew", ubuntu = "apt", arch = "pacman" }
local packages = platform.packages(profile, assert(managers[profile], "unknown TEST_PROFILE"))

for _, package in ipairs(packages.packages) do
  envy.stdout("package " .. package .. "\n")
end
for _, cask in ipairs(packages.casks) do
  envy.stdout("cask " .. cask .. "\n")
end
for _, tap in ipairs(packages.taps) do
  envy.stdout("tap " .. tap .. "\n")
end
