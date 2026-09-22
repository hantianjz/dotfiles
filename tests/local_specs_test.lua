local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end

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

print("local spec tests passed")
