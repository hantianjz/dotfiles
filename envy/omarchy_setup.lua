-- Invoked by setup after checking the Omarchy version and session.
local script = debug.getinfo(1, "S").source:sub(2)
local root = assert(script:match("^(.*)/envy/omarchy_setup.lua$"), "invoke with an absolute script path")
local home = assert(os.getenv("HOME"), "HOME is not set")
local directory = home .. "/.config/hypr"
local platform = dofile(root .. "/envy/platform.lua")
local links = platform.desktop_links("arch", root, home)

local function quote(value) return string.format("%q", value) end
local function run(command, check)
  return envy.run(command, { capture = true, quiet = true, check = check ~= false })
end
local function test(expression) return run("test " .. expression, false).exit_code == 0 end
local function exists(path) return test("-e " .. quote(path)) or test("-L " .. quote(path)) end
local function target(path)
  if test("-L " .. quote(path)) then
    return run("readlink " .. quote(path)).stdout:gsub("\n$", "")
  end
end
local function validate()
  run("hyprctl reload")
  -- Read diagnostic text: JSON can encode no errors as either [] or [""].
  local errors = run("hyprctl configerrors").stdout
  assert(not errors:find("%S"), "Hyprland configuration errors: " .. errors)
end

-- Do not resolve a directory-wide link and mutate an unexpected tree.
assert(not test("-L " .. quote(directory)), "expected a real Hypr directory, not a symlink: " .. directory)
assert(not exists(directory) or test("-d " .. quote(directory)), "not a directory: " .. directory)
local changed, retired = {}, {}
for _, link in ipairs(links) do
  assert(io.open(link.source, "r"), "missing source: " .. link.source):close()
  if link.source:match("%.lua$") then assert(loadfile(link.source)) end
  local symlink = target(link.dest)
  assert(symlink or not test("-d " .. quote(link.dest)), "refusing directory destination: " .. link.dest)
  assert(symlink or not exists(link.dest) or test("-f " .. quote(link.dest)),
    "unsupported destination type: " .. link.dest)
  if symlink ~= link.source then table.insert(changed, link) end
end
for _, name in ipairs({ "autostart", "bindings", "envs", "hypridle", "hyprland", "hyprlock", "input", "looknfeel", "monitors" }) do
  local dest = directory .. "/" .. name .. ".conf"
  if target(dest) == root .. "/config/hypr/" .. name .. ".conf" then table.insert(retired, dest) end
end

-- Dependencies first, entrypoint last, without changing the shared platform API.
for index, link in ipairs(links) do
  if link.dest == directory .. "/hyprland.lua" then
    table.insert(links, table.remove(links, index))
    break
  end
end
if #changed == 0 and #retired == 0 then
  validate()
  print("Omarchy configuration already linked; reload passed")
  return
end

local backup = run("mktemp -d " .. quote(home .. "/omarchy-config-backup.XXXXXX")).stdout:gsub("%s+$", "")
print("Omarchy configuration backup: " .. backup)
if exists(directory) then
  run("cp -a " .. quote(directory) .. " " .. quote(backup .. "/hypr-links"))
  run("mkdir " .. quote(backup .. "/hypr-resolved"))
  local entries = run("find " .. quote(directory) .. " -mindepth 1 -maxdepth 1 -print0").stdout
  for path in entries:gmatch("([^%z]+)%z") do
    if test("-L " .. quote(path)) and not test("-e " .. quote(path)) then
      -- Updating this checkout can leave retired .conf links dangling.
      -- Their targets are recorded in hypr-links, but the bytes are gone.
      envy.warn("unavailable dangling-link content: " .. path .. " -> " .. target(path))
      local missing = assert(io.open(backup .. "/unavailable", "a"))
      assert(missing:write(path .. "\n"))
      assert(missing:close())
    else
      local copied = run("cp -aL " .. quote(path) .. " " .. quote(backup .. "/hypr-resolved/"), false)
      assert(copied.exit_code == 0,
        "resolved backup failed for " .. path .. "; no destinations moved. Backup retained: " .. backup ..
        "\nMissing/dangling source bytes have NOT been backed up.\n" .. (copied.stderr or ""))
    end
  end
end
run("mkdir -p " .. quote(backup .. "/displaced") .. " " .. quote(backup .. "/retired"))
local touched = {}
local ok, failure = pcall(function()
  for _, link in ipairs(changed) do
    local saved
    if exists(link.dest) then
      saved = backup .. "/displaced/" .. link.dest:match("[^/]+$")
      run("mv " .. quote(link.dest) .. " " .. quote(saved))
    end
    table.insert(touched, { link = link, saved = saved })
  end
  dofile(root .. "/envy/local.symlink@r0.lua")
  if not SETUP.links.CHECK(nil, { links = links }) then
    run(SETUP.links.INSTALL(nil, { links = links }))
  end
  for _, link in ipairs(links) do
    assert(target(link.dest) == link.source, "destination not adopted: " .. link.dest)
    assert(io.open(link.dest, "r"), "unreadable destination: " .. link.dest):close()
  end
  validate()
end)
if not ok then
  local restored = true
  for index = #touched, 1, -1 do
    local entry = touched[index]
    local dest = entry.link.dest
    local success, reason = pcall(function()
      if exists(dest) then
        assert(target(dest) == entry.link.source, "destination changed during setup: " .. dest)
        run("rm " .. quote(dest))
      end
      if entry.saved then run("mv " .. quote(entry.saved) .. " " .. quote(dest)) end
    end)
    if not success then restored = false; envy.warn("restore failed: " .. tostring(reason)) end
  end
  if restored then
    local reloaded, reason = pcall(validate)
    if not reloaded then envy.warn("restored files, but reload failed: " .. tostring(reason)) end
  end
  error("Omarchy deployment failed: " .. tostring(failure) .. "\nBackup retained: " .. backup ..
    (restored and "\nOriginal managed destinations restored." or "\nRestore incomplete; inspect errors above."))
end

-- Retire only exact checkout-owned links after compositor validation.
for _, dest in ipairs(retired) do
  if target(dest) == root .. "/config/hypr/" .. dest:match("[^/]+$") then
    run("mv " .. quote(dest) .. " " .. quote(backup .. "/retired/" .. dest:match("[^/]+$")))
  end
end
print("Omarchy configuration deployed and reloaded; backup retained: " .. backup)
print("Verify shortcuts, physical keys, display scaling, and password/fingerprint unlock manually.")
