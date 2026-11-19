local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(value) return "'" .. value:gsub("'", [['"'"']]) .. "'" end
local function put(path, content)
  local file = assert(io.open(path, "w")); assert(file:write(content)); assert(file:close())
end
local temp = envy.run("mktemp -d /tmp/tree-sitter-setup-test.XXXXXX", { capture = true }).stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  local home = temp .. "/home with spaces"
  envy.run("mkdir -p " .. quote(home))
  put(temp .. "/tree-sitter", "#!/bin/sh\nexit 0\n")
  local scope = setmetatable({ envy = {
    run = function(command, options)
      return envy.run("HOME=" .. quote(home) .. " bash -c " .. quote(command), options)
    end,
  } }, { __index = _G })
  assert(loadfile(root .. "/envy/local.tree_sitter@r0.lua", "t", scope))()
  local setup = scope.SETUP.tools
  local function install() scope.envy.run(setup.INSTALL(temp)) end
  assert(not setup.CHECK(temp), "missing CLI must need installation")
  install()
  assert(setup.CHECK(temp), "installed executable must satisfy setup")
  put(home .. "/.local/bin/tree-sitter", "#!/bin/sh\nexit 1\n")
  assert(not setup.CHECK(temp), "stale CLI must need repair")
  install()
  assert(setup.CHECK(temp), "repair must restore the verified binary")
  envy.run("chmod -x " .. quote(home .. "/.local/bin/tree-sitter"))
  assert(not setup.CHECK(temp), "non-executable CLI must need repair")
  install()
  assert(setup.CHECK(temp), "repair must restore executable permissions")
end)
envy.run("rm -rf " .. quote(temp))
assert(ok, failure)
print("Tree-sitter setup tests passed: missing, stale, and non-executable CLI repair")
