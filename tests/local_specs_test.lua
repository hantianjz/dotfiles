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

print("local spec tests passed")
