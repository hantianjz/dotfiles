local real_envy = envy
local root = debug.getinfo(1, "S").source:sub(2):match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(value) return string.format("%q", value) end
local function run(command, environment)
  return real_envy.run(command, { capture = true, quiet = true, check = false, env = environment })
end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local temp = run("mktemp -d /tmp/tmx-release-test.XXXXXX").stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  local function fixture(name, suffix, receipt)
    local home = temp .. "/" .. name .. " home"
    local cargo_root = home .. suffix
    assert(run("mkdir -p " .. quote(home .. "/.cargo/bin") .. " " .. quote(cargo_root .. "/bin") ..
      " " .. quote(home .. "/payload")).exit_code == 0)
    put(cargo_root .. "/.crates.toml", "fixture\n")
    put(home .. "/receipt", receipt)
    put(home .. "/.cargo/bin/cargo", [[#!/bin/sh
set -eu
case "$1 $2" in
  'install --list') if test -f "$HOME/receipt"; then cat "$HOME/receipt"; fi ;;
  'uninstall --root') test "$4" = tmx; rm "$3/bin/tmx" "$3/bin/hmx" "$HOME/receipt" ;;
  *) exit 99 ;;
esac
]])
    for _, binary in ipairs({ "tmx", "hmx" }) do
      put(cargo_root .. "/bin/" .. binary, "#!/bin/sh\nprintf 'legacy\\n'\n")
      put(home .. "/payload/" .. binary, "#!/bin/sh\nprintf 'release\\n'\n")
    end
    assert(run("chmod +x " .. quote(home .. "/.cargo/bin/cargo") .. " " .. quote(cargo_root .. "/bin") .. "/*").exit_code == 0)
    local environment = { HOME = home, CARGO_INSTALL_ROOT = cargo_root, CARGO_HOME = home .. "/.cargo" }
    local scope = setmetatable({
      os = setmetatable({ getenv = function(key) return environment[key] or os.getenv(key) end }, { __index = os }),
      envy = { run = function(command, options)
        options.env = environment
        return real_envy.run(command, options)
      end },
    }, { __index = _G })
    assert(loadfile(root .. "/envy/local.tmx@r0.lua", "t", scope))()
    return home, scope.SETUP.tools, environment
  end
  local owned = "tmx v0.0.6 (https://github.com/hantianjz/tmx.git?rev=abc#abc):\n    hmx\n    tmx\n"
  local home, setup, environment = fixture("overlap", "/.local", owned)
  assert(not setup.CHECK(home .. "/payload"))
  assert(run(setup.INSTALL(home .. "/payload"), environment).exit_code == 0)
  for _, binary in ipairs({ "tmx", "hmx" }) do
    assert(run(quote(home .. "/.local/bin/" .. binary), environment).stdout == "release\n",
      "Cargo uninstall must not remove the new binaries when install roots overlap")
  end
  assert(setup.CHECK(home .. "/payload"), "migration must converge without old Cargo ownership")

  home, setup, environment = fixture("failure", "/.local", owned)
  assert(os.remove(home .. "/payload/hmx"))
  assert(run(setup.INSTALL(home .. "/payload"), environment).exit_code ~= 0)
  for _, binary in ipairs({ "tmx", "hmx" }) do
    assert(run(quote(home .. "/.local/bin/" .. binary), environment).stdout == "legacy\n",
      "failed staging must preserve both old binaries")
  end
  assert(run("test -f " .. quote(home .. "/receipt")).exit_code == 0, "failed staging must preserve Cargo ownership")

  home, setup, environment = fixture("unrelated", "/.cargo", "tmx v1.0.0 (https://github.com/other/tmx):\n    tmx\n")
  assert(run(setup.INSTALL(home .. "/payload"), environment).exit_code == 0)
  assert(run(quote(home .. "/.cargo/bin/tmx"), environment).stdout == "legacy\n", "foreign Cargo source must remain untouched")
  assert(run("test -f " .. quote(home .. "/receipt")).exit_code == 0)
  assert(setup.CHECK(home .. "/payload"))
end)
assert(run("rm -rf " .. quote(temp)).exit_code == 0)
assert(ok, failure)
print("tmx release migration tests passed")
