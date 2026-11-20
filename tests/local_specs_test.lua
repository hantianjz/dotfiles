local real_envy = envy
local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end

local calls = {}
envy = {
  run = function(command, options)
    table.insert(calls, { command = command, options = options })
    return { exit_code = command == "probe succeeds" and 0 or 1, stdout = "" }
  end,
}

dofile(root .. "/envy/local.shell@r0.lua")
assert(not SETUP.command.CHECK(nil, { check = "probe fails" }))
assert(calls[1].options.check == false, "a failed shell probe must not abort setup")
assert(SETUP.command.CHECK(nil, { check = "probe succeeds" }))
assert(SETUP.command.INSTALL(nil, { install = "install command" }) == "install command")

envy = real_envy
local function quote(value) return string.format("%q", value) end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local temp = envy.run("mktemp -d /tmp/local-specs-test.XXXXXX", { capture = true }).stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  envy.run("mkdir -p " .. quote(temp .. "/bin"))
  put(temp .. "/system.lua", [[
IDENTITY = "local.system_packages@r0"
USER_MANAGED = true
SETUP = { packages = { CHECK = "false", INSTALL = 'touch "$HOME/native-ready"' } }
]])
  put(temp .. "/envy.lua", string.format([[
-- @envy version "0.5.1"
-- @envy bin "bin"
PACKAGES = {
  { spec = "local.system_packages@r0", source = %q },
  { spec = "local.symlink@r0", source = %q,
    options = { links = { { source = %q, dest = %q } } } },
  { spec = "local.shell@r0", source = %q, setup = { "command" },
    options = { check = 'test -f "$HOME/fisher-ready"',
      install = 'test -f "$HOME/native-ready" && test -L "$HOME/.bashrc" && touch "$HOME/fisher-ready"' } },
}
]], temp .. "/system.lua",
    root .. "/envy/local.symlink@r0.lua", root .. "/config/shellrc/bashrc", temp .. "/.bashrc",
    root .. "/envy/local.shell@r0.lua"))
  local bootstrap_cache = os.getenv("ENVY_CACHE_ROOT") or
    (assert(os.getenv("HOME")) .. (envy.PLATFORM == "darwin" and "/Library/Caches/envy" or "/.cache/envy"))
  local command = "ENVY_CACHE_ROOT=" .. quote(bootstrap_cache) .. " HOME=" .. quote(temp) ..
    " PATH=" .. quote(temp .. "/bin:/usr/bin:/bin") .. " " .. quote(root .. "/bin/envy") ..
    " --cache-root " .. quote(temp .. "/cache") .. " install --manifest " .. quote(temp .. "/envy.lua")
  local result = envy.run(command, { capture = true, check = false })
  assert(result.exit_code == 0, result.stderr)
  envy.run("test -f " .. quote(temp .. "/fisher-ready"))
  local fish = envy.run("command -v fish", { capture = true }).stdout:gsub("%s+$", "")
  envy.run("ln -s " .. quote(fish) .. " " .. quote(temp .. "/bin/fish"))
  -- This unit check exercises Fisher, not the separate GitHub dependency graph.
  local manifest = setmetatable({
    envy = setmetatable({ import = function() return { PACKAGES = {} } end }, { __index = envy }),
  }, { __index = _G })
  assert(loadfile(root .. "/envy.lua", "t", manifest))()
  local fisher_check
  for _, package in ipairs(manifest.PACKAGES) do
    if package.spec == "local.shell@r0" and package.options.check:match("^fish ") then
      fisher_check = package.options.check
    end
  end
  assert(fisher_check)
  local config = temp .. "/fisher-home/.config/fish"
  envy.run("mkdir -p " .. quote(config .. "/functions"))
  put(config .. "/fish_plugins", "owner/one\nowner/two\n")
  local function check_fisher()
    local command = "'" .. fisher_check:gsub("'", [['"'"']]) .. "'"
    return envy.run("env -i HOME=" .. quote(temp .. "/fisher-home") .. " XDG_CONFIG_HOME=" ..
      quote(temp .. "/fisher-home/.config") .. " PATH=" .. quote(temp .. "/bin:/usr/bin:/bin") ..
      " bash -c " .. command, { capture = true, check = false }).exit_code == 0
  end
  assert(not check_fisher(), "absent Fisher must need installation")
  put(config .. "/functions/fisher.fish", 'function fisher; printf "%s\\n" owner/one; end\n')
  assert(not check_fisher(), "manager presence must not hide a missing declared plugin")
  put(config .. "/functions/fisher.fish", 'function fisher; printf "%s\\n" owner/one owner/two; end\n')
  assert(check_fisher(), "complete declared inventory must satisfy setup")

  dofile(root .. "/envy/local.symlink@r0.lua")
  for _, scenario in ipairs({ "fresh", "migrated", "native" }) do
    local home = temp .. "/bash-" .. scenario
    envy.run("mkdir -p " .. quote(home .. "/.cargo/bin"))
    if scenario == "migrated" then
      envy.run("ln -s " .. quote(root .. "/shellrc/profile") .. " " .. quote(home .. "/.profile"))
    elseif scenario == "native" then
      put(home .. "/.profile", '. "$HOME/.bashrc"\nexport NATIVE_PROFILE=loaded\n')
    end
    local linux_manifest = setmetatable({
      os = setmetatable({ getenv = function(name) return name == "HOME" and home or os.getenv(name) end }, { __index = os }),
      envy = setmetatable({
        PLATFORM = "linux",
        import = function() return { PACKAGES = {} } end,
        run = function(cmd, options)
          if cmd == "command -v pacman" then return { exit_code = 1 } end
          if cmd == "command -v apt-get" or cmd == "command -v dpkg-query" then return { exit_code = 0 } end
          options.env = { HOME = home }
          return envy.run(cmd, options)
        end,
      }, { __index = envy }),
    }, { __index = _G })
    assert(loadfile(root .. "/envy.lua", "t", linux_manifest))()
    for _, package in ipairs(linux_manifest.PACKAGES) do
      if package.spec == "local.symlink@r0" and not SETUP.links.CHECK(nil, package.options) then
        envy.run(SETUP.links.INSTALL(nil, package.options))
      end
    end
    local login = envy.run("env -i HOME=" .. quote(home) .. [=[ PATH=/usr/bin:/bin TERM=dumb /bin/bash -lic '
      alias ll >/dev/null && [[ :$PATH: == *":$HOME/.cargo/bin:"* ]] && printf "%s\n" "${NATIVE_PROFILE:-managed}"
    ']=], { capture = true })
    assert(login.exit_code == 0 and login.stdout == (scenario == "native" and "loaded\n" or "managed\n"),
      string.format("Bash login failed (%s, exit %d): %q %q", scenario, login.exit_code, login.stdout, login.stderr))
  end

  dofile(root .. "/envy/local.rustup@r0.lua")
  local startup = temp .. "/rustup-home"
  envy.run("mkdir -p " .. quote(startup))
  put(startup .. "/.profile", "# user profile\n")
  put(startup .. "/.bashrc", "# user bashrc\n")
  put(temp .. "/bin/curl", [[#!/bin/sh
cat <<'INSTALLER'
case " $* " in *" --no-modify-path "*) exit 0 ;; esac
printf '. "$HOME/.cargo/env"\n' >> "$HOME/.profile"
printf '. "$HOME/.cargo/env"\n' >> "$HOME/.bashrc"
INSTALLER
]])
  local install = "'" .. SETUP.rustup.INSTALL():gsub("'", [['"'"']]) .. "'"
  envy.run("env -i HOME=" .. quote(startup) .. " PATH=" .. quote(temp .. "/bin:/usr/bin:/bin") ..
    " bash -c " .. install, { capture = true })
  for file, expected in pairs({ [".profile"] = "# user profile\n", [".bashrc"] = "# user bashrc\n" }) do
    local handle = assert(io.open(startup .. "/" .. file)); local actual = handle:read("*a"); handle:close()
    assert(actual == expected, "Rustup must preserve startup files")
  end
end)
envy.run("rm -rf " .. quote(temp))
assert(ok, failure)

print("local spec tests passed")
