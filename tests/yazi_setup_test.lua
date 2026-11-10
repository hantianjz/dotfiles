local real_envy = envy
local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(value) return string.format("%q", value) end
local function run(command, check)
  return real_envy.run(command, { capture = true, quiet = true, check = check ~= false })
end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local function contents(path)
  local file = assert(io.open(path)); local value = file:read("*a"); file:close(); return value
end
local temp = run("mktemp -d /tmp/yazi-setup-test.XXXXXX").stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  local commands = temp .. "/commands"
  run("mkdir -p " .. quote(commands))
  put(commands .. "/dpkg-query", [[#!/bin/sh
set -eu
test -f "$HOME/native-version" || exit 1
status='install ok installed'
if test -f "$HOME/native-status"; then status=$(cat "$HOME/native-status"); fi
printf '%s\t%s\n' "$status" "$(cat "$HOME/native-version")"
]])
  put(commands .. "/sudo", '#!/bin/sh\nexec "$@"\n')
  put(commands .. "/apt-get", [[#!/bin/sh
set -eu
test "$1" = install
if test -f "$HOME/apt-fails"; then exit 42; fi
for argument do deb=$argument; done
test -f "$deb"
printf '26.9.1-1\n' > "$HOME/native-version"
printf 'install\n' >> "$HOME/native-installs"
]])
  put(commands .. "/cargo", [[#!/bin/sh
set -eu
case "$1 $2" in
  'install --list')
    for name in yazi-build yazi-fm yazi-cli; do
      if test -f "$HOME/registered.$name"; then printf '%s v26.9.1:\n' "$name"; fi
    done ;;
  'uninstall --root')
    name=$4
    test -f "$HOME/registered.$name"
    case "$name" in yazi-build) binary=yazi-build;; yazi-fm) binary=yazi;; yazi-cli) binary=ya;; *) exit 99;; esac
    rm "$HOME/registered.$name" "$HOME/.cargo/bin/$binary" ;;
  *) exit 98 ;;
esac
]])
  run("chmod +x " .. quote(commands) .. "/*")
  local function fixture(name)
    local home = temp .. "/" .. name .. " home"
    run("mkdir -p " .. quote(home .. "/.cargo/bin") .. " " .. quote(home .. "/.local/bin") .. " " .. quote(home .. "/payload"))
    put(home .. "/payload/yazi-x86_64-unknown-linux-gnu.deb", "fixture deb\n")
    run("ln -s " .. quote(commands .. "/cargo") .. " " .. quote(home .. "/.cargo/bin/cargo"))
    local environment = { HOME = home, PATH = commands .. ":" .. assert(os.getenv("PATH")),
      CARGO_HOME = home .. "/.cargo", CARGO_INSTALL_ROOT = home .. "/.cargo" }
    local scope = setmetatable({
      os = setmetatable({ getenv = function(key) return environment[key] or os.getenv(key) end }, { __index = os }),
      envy = { PLATFORM = "linux", ARCH = "x86_64", run = function(command, options)
        options = options or {}; options.env = environment
        return real_envy.run(command, options)
      end },
    }, { __index = _G })
    assert(loadfile(root .. "/envy/local.yazi@r0.lua", "t", scope))()
    return home, scope.SETUP.package
  end
  local function legacy(home, name, title)
    put(home .. "/.cargo/.crates2.json", "{}\n")
    put(home .. "/registered." .. name, "registered\n")
    local binary = name == "yazi-build" and "yazi-build" or name == "yazi-fm" and "yazi" or "ya"
    put(home .. "/.cargo/bin/" .. binary, "#!/bin/sh\nprintf '" .. (title or "legacy") .. "\\n'\n")
    run("chmod +x " .. quote(home .. "/.cargo/bin/" .. binary))
  end

  local home, setup = fixture("fresh")
  assert(not setup.CHECK())
  setup.INSTALL(home .. "/payload")
  assert(setup.CHECK(), "native exact version must converge")
  setup.INSTALL(home .. "/payload")
  assert(contents(home .. "/native-installs") == "install\n", "converged setup must not invoke apt")
  put(home .. "/native-status", "deinstall ok config-files")
  assert(not setup.CHECK(), "version alone must not satisfy native installation")
  run("rm " .. quote(home .. "/native-status"))
  put(home .. "/native-version", "25.5.31-1\n")
  assert(not setup.CHECK(), "wrong native version must request pinned deb")
  setup.INSTALL(home .. "/payload")
  assert(setup.CHECK())

  home, setup = fixture("installer")
  legacy(home, "yazi-build")
  for _, entry in ipairs({ { "yazi", "Yazi" }, { "ya", "Ya" } }) do
    put(home .. "/.cargo/bin/" .. entry[1], "#!/bin/sh\nprintf '" .. entry[2] .. "\\n    Version: 26.9.1 (fixture)\\n'\n")
    run("chmod +x " .. quote(home .. "/.cargo/bin/" .. entry[1]))
  end
  put(home .. "/.cargo/bin/keep", "unrelated manual binary\n")
  local old_yazi = contents(home .. "/.cargo/bin/yazi")
  put(home .. "/apt-fails", "fail\n")
  assert(not pcall(setup.INSTALL, home .. "/payload"), "apt failure must abort migration")
  assert(contents(home .. "/.cargo/bin/yazi") == old_yazi, "apt failure must preserve existing app")
  assert(contents(home .. "/registered.yazi-build") == "registered\n")
  run("rm " .. quote(home .. "/apt-fails"))
  setup.INSTALL(home .. "/payload")
  assert(setup.CHECK(), "unregistered installer outputs must no longer shadow native app")
  assert(contents(home .. "/.cargo/bin/keep") == "unrelated manual binary\n")
  local saved = run("cat " .. quote(home .. "/.cargo") .. "/.yazi-before-native.*/yazi").stdout
  assert(saved == old_yazi, "unregistered output must be preserved, not guessed safe to delete")

  home, setup = fixture("registered")
  legacy(home, "yazi-fm"); legacy(home, "yazi-cli")
  setup.INSTALL(home .. "/payload")
  assert(setup.CHECK(), "old registered Cargo packages must be uninstalled")

  home, setup = fixture("manual")
  legacy(home, "yazi-build")
  put(home .. "/.cargo/bin/yazi", "#!/bin/sh\nprintf 'manual tool\\n'\n")
  run("chmod +x " .. quote(home .. "/.cargo/bin/yazi"))
  local manual = contents(home .. "/.cargo/bin/yazi")
  assert(not pcall(setup.INSTALL, home .. "/payload"), "unknown manual binary must require explicit relocation")
  assert(contents(home .. "/.cargo/bin/yazi") == manual)
  assert(contents(home .. "/registered.yazi-build") == "registered\n")
  run("test ! -e " .. quote(home .. "/native-installs"))
end)
run("rm -rf " .. quote(temp))
assert(ok, failure)
print("Yazi setup tests passed")
