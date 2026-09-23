local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(s) return "'" .. s:gsub("'", [['"'"']]) .. "'" end
local run = envy.run
local function put(path, content)
  local file = assert(io.open(path, "w")); assert(file:write(content)); assert(file:close())
end
local temp = run("mktemp -d /tmp/omp-setup-test.XXXXXX", { capture = true }).stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  run("mkdir -p " .. quote(temp .. "/bin") .. " " .. quote(temp .. "/home with spaces"))
  for _, command in ipairs({ "bash", "sh", "cat", "cp", "chmod", "mkdir", "dirname", "jq" }) do
    local binary = run("command -v " .. command, { capture = true }).stdout:gsub("%s+$", "")
    run("ln -s " .. quote(binary) .. " " .. quote(temp .. "/bin/" .. command))
  end
  put(temp .. "/bun", [[#!/bin/sh
if [ "${1:-}" = upgrade ]; then : > "$HOME/bun-updated"; fi
]])
  put(temp .. "/omp", [[#!/bin/sh
set -eu
case "$*" in
  'plugin list --json')
    if [ -f "$HOME/plugin-enabled" ]; then
      echo '{"npm":[{"name":"omp-ponytail-caveman","enabled":true}]}'
    else
      echo '{"npm":[]}'
    fi ;;
  'plugin install github:phenome/omp-ponytail-caveman')
    command -v bun >/dev/null
    : > "$HOME/plugin-enabled" ;;
  update) : > "$HOME/omp-updated" ;;
  *) exit 1 ;;
esac
]])
  -- Replace only network downloads; execute the recipe's real shell control flow.
  put(temp .. "/bin/curl", [[#!/bin/sh
set -eu
[ ! -f "$HOME/download-fails" ] || exit 22
case "$2" in
  https://bun.sh/install) echo 'mkdir -p "$BUN_INSTALL/bin"; cp "$FIXTURES/bun" "$BUN_INSTALL/bin/bun"' ;;
  https://omp.sh/install.sh) echo 'mkdir -p "$PI_INSTALL_DIR"; cp "$FIXTURES/omp" "$PI_INSTALL_DIR/omp"' ;;
  *) exit 1 ;;
esac
]])
  run("chmod +x " .. quote(temp .. "/bun") .. " " .. quote(temp .. "/omp") .. " " .. quote(temp .. "/bin/curl"))
  local prefix = "env -i HOME=" .. quote(temp .. "/home with spaces") .. " PATH=" .. quote(temp .. "/bin") ..
    " FIXTURES=" .. quote(temp) .. " " .. quote(temp .. "/bin/bash") .. " -c "
  envy.run = function(command, options) return run(prefix .. quote(command), options) end
  dofile(root .. "/envy/local.omp@r0.lua")
  assert(not SETUP.tools.CHECK(), "fresh home must need setup")
  put(temp .. "/home with spaces/download-fails", "")
  assert(envy.run(SETUP.tools.INSTALL(), { capture = true, check = false }).exit_code ~= 0,
    "failed downloads must fail setup")
  os.remove(temp .. "/home with spaces/download-fails")
  envy.run(SETUP.tools.INSTALL())
  assert(SETUP.tools.CHECK(), "installed tools and plugin must satisfy setup")
  os.remove(temp .. "/home with spaces/.bun/bin/bun")
  assert(not SETUP.tools.CHECK(), "installed plugin must not hide missing Bun")
  envy.run(SETUP.tools.INSTALL())
  os.remove(temp .. "/home with spaces/plugin-enabled")
  assert(not SETUP.tools.CHECK(), "missing plugin must need setup")
  envy.run(quote(root .. "/bin/update"))
  assert(SETUP.tools.CHECK(), "update must refresh the Git-source plugin")
  for _, marker in ipairs({ "bun-updated", "omp-updated" }) do
    local file = assert(io.open(temp .. "/home with spaces/" .. marker)); file:close()
  end
end)
envy.run = run
run("rm -rf " .. quote(temp))
assert(ok, failure)
print("omp setup tests passed: installation, convergence, failed downloads, and updates")
