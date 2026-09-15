local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end

local function quote(value)
  return string.format("%q", value)
end

local function run(command, check)
  return envy.run(command, { capture = true, quiet = true, check = check ~= false })
end

local temp = run("mktemp -d /tmp/envy-symlink-test.XXXXXX").stdout:gsub("%s+$", "")
local source = temp .. "/source with spaces"
local file_source = temp .. "/file source"
local alternate = temp .. "/alternate"
local destinations = temp .. "/destinations"
run("mkdir -p " .. quote(source) .. " " .. quote(alternate) .. " " .. quote(destinations))

local links = {
  { source = source, dest = destinations .. "/missing link" },
  { source = source, dest = destinations .. "/correct link" },
  { source = source, dest = destinations .. "/stale link" },
  { source = source, dest = destinations .. "/broken link" },
  { source = source, dest = destinations .. "/real directory" },
  { source = source, dest = destinations .. "/real file" },
  { source = file_source, dest = destinations .. "/identical file" },
}

run("ln -s " .. quote(source) .. " " .. quote(links[2].dest))
run("ln -s " .. quote(alternate) .. " " .. quote(links[3].dest))
run("ln -s " .. quote(temp .. "/does-not-exist") .. " " .. quote(links[4].dest))
run("mkdir -p " .. quote(links[5].dest))
run("touch " .. quote(links[6].dest))
run("touch " .. quote(file_source))
run("cp " .. quote(file_source) .. " " .. quote(links[7].dest))

local warnings = {}
local original_warn = envy.warn
envy.warn = function(message)
  table.insert(warnings, message)
end

dofile(root .. "/envy/local.symlink@r0.lua")
assert(not SETUP.links.CHECK(nil, { links = links }), "actionable links should make the check fail")
assert(#warnings == 2, "real file and directory should each produce a warning")

local install = SETUP.links.INSTALL(nil, { links = links })
run(install)

for index = 1, 4 do
  local result = run("readlink " .. quote(links[index].dest)).stdout:gsub("%s+$", "")
  assert(result == source, "link " .. index .. " did not resolve to the expected source")
end

local adopted = run("readlink " .. quote(links[7].dest)).stdout:gsub("%s+$", "")
assert(adopted == file_source, "an identical regular file should be adopted as a symlink")

assert(run("test -d " .. quote(links[5].dest), false).exit_code == 0)
assert(run("test -f " .. quote(links[6].dest), false).exit_code == 0)
assert(run("test ! -e " .. quote(links[5].dest .. "/source with spaces"), false).exit_code == 0,
  "the source must not be linked inside an existing directory")

warnings = {}
assert(SETUP.links.CHECK(nil, { links = links }), "second check should be idempotent")
assert(#warnings == 2, "preserved conflicts should continue to warn")

envy.warn = original_warn
run("rm -rf " .. quote(temp))
print("symlink policy tests passed")
