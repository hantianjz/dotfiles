local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local original_run = envy.run
local function quote(s) return string.format("%q", s) end
local function run(s) return original_run(s, { capture = true, quiet = true }) end
local function contents(path)
  local file = assert(io.open(path)); local value = file:read("*a"); file:close(); return value
end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); file:close()
end
local temp = run("mktemp -d /tmp/omarchy-setup-test.XXXXXX").stdout:gsub("%s+$", "")
local function scenario(name, mode, prepare, verify)
  local home = temp .. "/" .. name
  local hypr = home .. "/.config/hypr"
  run("mkdir -p " .. quote(hypr))
  prepare(hypr)
  local reloads = 0
  envy.run = function(command, options)
    if command == "hyprctl reload" then
      reloads = reloads + 1
      return { exit_code = 0, stdout = "ok\n" }
    elseif command == "hyprctl -j configerrors" or command == "hyprctl configerrors" then
      if mode == "ipc-error" and reloads == 1 then error("hyprctl IPC unavailable") end
      local message = mode == "parse-error" and reloads == 1 and "invalid config" or ""
      -- Hyprland splits even an empty error buffer into one diagnostic line.
      local response = command == "hyprctl -j configerrors"
        and ('[\n  "' .. message .. '"\n]\n') or ("\n" .. message .. "\n")
      return { exit_code = 0, stdout = response }
    elseif mode == "install-error" and command:find("ln -sfn", 1, true) then
      -- Actually install the first link, then fail before the rest.
      run(assert(command:match("^(.- && .-) && ")))
      error("injected partial installation failure")
    elseif mode == "backup-error" and command:match("^cp %-aL ") then
      return { exit_code = 1, stdout = "", stderr = "injected copy failure" }
    end
    return original_run(command, options)
  end
  local context = setmetatable({ os = { getenv = function(key)
    return key == "HOME" and home or os.getenv(key)
  end } }, { __index = _G })
  local execute = assert(loadfile(root .. "/envy/omarchy_setup.lua", "t", context))
  local ok, err = pcall(execute)
  envy.run = original_run
  verify(ok, err, hypr, home, execute, reloads)
end

local ok, err = pcall(function()
  scenario("adopt", "success", function(hypr)
    put(hypr .. "/input.lua", "-- personal input\n")
    put(hypr .. "/unrelated", "keep\n")
    put(hypr .. "/hypridle.conf", "user-owned retired file\n")
    run("ln -s " .. quote(root .. "/config/hypr/autostart.conf") .. " " .. quote(hypr .. "/autostart.conf"))
    run("ln -s /foreign/missing " .. quote(hypr .. "/bindings.conf"))
  end, function(success, failure, hypr, home)
    assert(success, failure)
    for _, link in ipairs(dofile(root .. "/envy/platform.lua").desktop_links("arch", root, home)) do
      assert(run("readlink " .. quote(link.dest)).stdout:gsub("\n$", "") == link.source)
    end
    assert(contents(hypr .. "/unrelated") == "keep\n")
    assert(contents(hypr .. "/hypridle.conf") == "user-owned retired file\n")
    assert(run("readlink " .. quote(hypr .. "/bindings.conf")).stdout == "/foreign/missing\n")
    run("test ! -L " .. quote(hypr .. "/autostart.conf"))
    local backup = run("find " .. quote(home) .. " -maxdepth 1 -name 'omarchy-config-backup.*'").stdout:gsub("\n$", "")
    assert(contents(backup .. "/displaced/input.lua") == "-- personal input\n")
    assert(contents(backup .. "/hypr-resolved/input.lua") == "-- personal input\n")
    assert(contents(backup .. "/unavailable"):find("autostart.conf", 1, true))
    run("test -L " .. quote(backup .. "/retired/autostart.conf"))
    -- Re-run with only the compositor boundary simulated: no second backup.
    envy.run = function(command, options)
      if command == "hyprctl reload" or command == "hyprctl configerrors" or command == "hyprctl -j configerrors" then
        local response = command == "hyprctl -j configerrors" and '[\n  ""\n]\n' or "\n"
        return { exit_code = 0, stdout = command == "hyprctl reload" and "ok\n" or response }
      end
      return original_run(command, options)
    end
    local context = setmetatable({ os = { getenv = function(key) return key == "HOME" and home or os.getenv(key) end } }, { __index = _G })
    assert(loadfile(root .. "/envy/omarchy_setup.lua", "t", context))()
    envy.run = original_run
    assert(run("find " .. quote(home) .. " -maxdepth 1 -name 'omarchy-config-backup.*'").stdout == backup .. "\n")
  end)

  for _, mode in ipairs({ "parse-error", "ipc-error", "install-error", "backup-error", "directory" }) do
    scenario(mode, mode, function(hypr)
      put(hypr .. "/input.lua", "-- original\n")
      put(hypr .. "/unrelated", "untouched\n")
      run("ln -s " .. quote(root .. "/config/hypr/xdph.conf") .. " " .. quote(hypr .. "/bindings.lua"))
      if mode == "directory" then run("mkdir " .. quote(hypr .. "/monitors.lua")) end
    end, function(success, failure, hypr)
      assert(not success, "expected " .. mode .. " failure")
      assert(contents(hypr .. "/input.lua") == "-- original\n")
      run("test ! -L " .. quote(hypr .. "/input.lua"))
      assert(run("readlink " .. quote(hypr .. "/bindings.lua")).stdout == root .. "/config/hypr/xdph.conf\n")
      assert(contents(hypr .. "/unrelated") == "untouched\n")
      run("test ! -e " .. quote(hypr .. "/hyprland.lua"))
      run("test ! -L " .. quote(hypr .. "/autostart.lua"))
      if mode == "directory" then
        assert(tostring(failure):find(hypr .. "/monitors.lua", 1, true))
        run("test -d " .. quote(hypr .. "/monitors.lua"))
      end
    end)
  end
end)
envy.run = original_run
run("rm -rf " .. quote(temp))
assert(ok, err)
print("Omarchy deployment tests passed: adoption, backup, idempotency, retirement ownership, directory refusal, copy/partial-install/parser failures and rollback")
