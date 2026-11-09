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

calls = {}
dofile(root .. "/envy/local.cargo_install@r0.lua")
assert(not SETUP.crates.CHECK(nil, { crates = { { package = "yazi-build", force = true } } }))
local install = SETUP.crates.INSTALL(nil, { crates = {} })
assert(install:match("cargo.*install %-%-force %-%-locked yazi%-build"),
  "forced Cargo packages must include --force")

calls = {}
local cargo_list = ""
envy = {
  run = function(command, options)
    table.insert(calls, { command = command, options = options })
    if command:match("install %-%-list") then
      return { exit_code = 0, stdout = cargo_list }
    end
    return { exit_code = 1, stdout = "" }
  end,
  package = function(query)
    assert(query == "envy.github@r0")
    return "/tmp/github source"
  end,
}
local cargo_github = dofile(root .. "/envy/cargo_github_tool.lua")
local github_tool = cargo_github.setup("tmx", "tmx")
cargo_list = "tmx v0.0.6:\n"
assert(github_tool.CHECK(), "installed GitHub Cargo package must satisfy check")
cargo_list = ""
assert(not github_tool.CHECK(), "missing GitHub Cargo package must request install")
github_tool.INSTALL()
assert(calls[#calls].command == 'cargo install --path "/tmp/github source/tmx" --locked',
  "GitHub Cargo install must use the cached source path")

envy = real_envy
local function quote(value) return string.format("%q", value) end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local temp = envy.run("mktemp -d /tmp/local-specs-test.XXXXXX", { capture = true }).stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  envy.run("mkdir -p " .. quote(temp .. "/.cargo/bin") .. " " .. quote(temp .. "/bin"))
  put(temp .. "/system.lua", [[
IDENTITY = "local.system_packages@r0"
USER_MANAGED = true
SETUP = { packages = { CHECK = "false", INSTALL = 'touch "$HOME/native-ready"' } }
]])
  put(temp .. "/toolchain.lua", [[
IDENTITY = "local.rustup_toolchain@r0"
USER_MANAGED = true
SETUP = { toolchain = { CHECK = "true", INSTALL = "false" } }
]])
  put(temp .. "/github.lua", [[
IDENTITY = "envy.github@r0"
USER_MANAGED = true
SETUP = { unused = { CHECK = "true", INSTALL = "false" } }
]])
  put(temp .. "/.cargo/bin/cargo", [[#!/bin/sh
set -eu
test -f "$HOME/native-ready"
test "$*" = "install --list"
printf 'tmx v0.0.6:\ndiskus v0.9.0:\n'
]])
  envy.run("chmod +x " .. quote(temp .. "/.cargo/bin/cargo"))
  put(temp .. "/bin/curl", [[#!/bin/sh
printf '%s\n' 'mkdir -p "$HOME/.local/bin"; cp "$HOME/fake-herdr" "$HOME/.local/bin/herdr"'
]])
  put(temp .. "/fake-herdr", [[#!/bin/sh
set -eu
test -f "$HOME/native-ready"
test -L "$HOME/environment"
test "$1 $2" = "plugin install"
mkdir -p "$HOME/.config/herdr/plugins/github/${3##*/}-fixture"
]])
  envy.run("chmod +x " .. quote(temp .. "/bin/curl") .. " " .. quote(temp .. "/fake-herdr"))
  put(temp .. "/herdr.lua", "dofile(" .. quote(root .. "/envy/local.herdr@r0.lua") ..
    ")\nSETUP.cli.PLATFORMS = nil\n")
  for _, recipe in ipairs({ "cargo_install", "cargo_github_tmx" }) do
    put(temp .. "/" .. recipe .. ".lua", string.format([[
envy.loadenv = function(name) return dofile(%q .. "/envy/" .. name .. ".lua") end
dofile(%q)
for _, dep in ipairs(DEPENDENCIES) do
  if dep.spec == "local.rustup_toolchain@r0" then dep.source = %q end
  if dep.spec == "envy.github@r0" then dep.bundle = nil; dep.source = %q end
end
]], root, root .. "/envy/local." .. recipe .. "@r0.lua", temp .. "/toolchain.lua", temp .. "/github.lua"))
  end
  put(temp .. "/envy.lua", string.format([[
-- @envy version "0.4.8"
-- @envy bin "bin"
PACKAGES = {
  { spec = "local.cargo_install@r0", source = %q, setup = { "crates" },
    options = { crates = { { package = "diskus" } } } },
  { spec = "local.cargo_github_tmx@r0", source = %q, setup = { "tool" } },
  { spec = "local.system_packages@r0", source = %q },
  { spec = "local.symlink@r0", source = %q,
    options = { links = { { source = %q, dest = %q } } } },
  { spec = "local.shell@r0", source = %q, setup = { "command" },
    options = { check = 'test -f "$HOME/fisher-ready"',
      install = 'test -f "$HOME/native-ready" && test -L "$HOME/environment" && touch "$HOME/fisher-ready"' } },
  { spec = "local.herdr@r0", source = %q, setup = { "plugins" },
    options = { plugins = { "owner/example" } } },
}
]], temp .. "/cargo_install.lua", temp .. "/cargo_github_tmx.lua", temp .. "/system.lua",
    root .. "/envy/local.symlink@r0.lua", root .. "/shellrc/environment", temp .. "/environment",
    root .. "/envy/local.shell@r0.lua", temp .. "/herdr.lua"))
  local bootstrap_cache = os.getenv("ENVY_CACHE_ROOT") or
    (assert(os.getenv("HOME")) .. (envy.PLATFORM == "darwin" and "/Library/Caches/envy" or "/.cache/envy"))
  local result = envy.run("ENVY_CACHE_ROOT=" .. quote(bootstrap_cache) .. " HOME=" .. quote(temp) ..
    " PATH=" .. quote(temp .. "/bin:/usr/bin:/bin") .. " " .. quote(root .. "/bin/envy") ..
    " --cache-root " .. quote(temp .. "/cache") .. " install --manifest " .. quote(temp .. "/envy.lua"),
    { capture = true, check = false })
  assert(result.exit_code == 0, result.stderr)
  envy.run("test -f " .. quote(temp .. "/fisher-ready") .. " && test -d " ..
    quote(temp .. "/.config/herdr/plugins/github/example-fixture"))
end)
envy.run("rm -rf " .. quote(temp))
assert(ok, failure)

print("local spec tests passed")
