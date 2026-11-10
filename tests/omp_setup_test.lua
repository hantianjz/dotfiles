local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(s) return "'" .. s:gsub("'", [['"'"']]) .. "'" end
local run = envy.run
root = run("cd " .. quote(root) .. " && pwd", { capture = true }).stdout:gsub("%s+$", "")
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
if [ "${1:-}" = upgrade ]; then
  [ ! -f "$HOME/update-fails" ] || exit 42
  : > "$HOME/bun-updated"
fi
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
  put(temp .. "/bin/brew", [[#!/bin/sh
set -eu
case "$*" in
  'install can1357/tap/omp') cp "$FIXTURES/omp" "$FIXTURES/bin/omp" ;;
  update) : ;;
  upgrade) : > "$HOME/omp-updated" ;;
  *) exit 1 ;;
esac
]])
  put(temp .. "/bin/uname", [[#!/bin/sh
printf '%s\n' "$TEST_PLATFORM"
]])
  run("chmod +x " .. quote(temp .. "/bun") .. " " .. quote(temp .. "/omp") .. " " ..
    quote(temp .. "/bin/curl") .. " " .. quote(temp .. "/bin/brew") .. " " .. quote(temp .. "/bin/uname"))
  local project = temp .. "/project with spaces"
  local updater = quote(project .. "/bin/update")
  run("mkdir -p " .. quote(project .. "/bin") .. " " .. quote(project .. "/scripts") .. " " ..
    quote(project .. "/tmux") .. " " .. quote(project .. "/config/herdr") .. " " ..
    quote(temp .. "/home with spaces/.config"))
  run("cp " .. quote(root .. "/bin/update") .. " " .. quote(project .. "/bin/update"))
  run("cp " .. quote(root .. "/scripts/with-build-temp") .. " " .. quote(project .. "/scripts/with-build-temp"))
  run("cp " .. quote(root .. "/config/herdr/plugins") .. " " .. quote(project .. "/config/herdr/plugins"))
  run("ln -s " .. quote(project .. "/tmux") .. " " .. quote(temp .. "/home with spaces/.config/tmux"))
  put(project .. "/bin/envy", [[#!/bin/sh
set -eu
[ "$#" -eq 4 ]
[ "$1" = --project ]
[ "$2" = "$FIXTURES/project with spaces" ]
[ "$3" = vendor ]
[ "$4" = --all ]
[ ! -f "$HOME/vendor-fails" ] || exit 43
: > "$HOME/tmux-vendored"
]])
  put(temp .. "/bin/fish", [[#!/bin/sh
set -eu
case "$*" in
  '-c type -q fisher') : ;;
  '-c fisher update') : > "$HOME/fisher-updated" ;;
  *) exit 1 ;;
esac
]])
  run("chmod +x " .. quote(project .. "/bin/envy") .. " " .. quote(temp .. "/bin/fish"))
  local prefix = "env -i HOME=" .. quote(temp .. "/home with spaces") .. " PATH=" .. quote(temp .. "/bin") ..
    " TEST_PLATFORM=" .. quote(os.getenv("OMP_TEST_PLATFORM") or "Darwin") ..
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
  envy.run(updater)
  assert(SETUP.tools.CHECK(), "update must refresh the Git-source plugin")
  for _, marker in ipairs({ "bun-updated", "omp-updated", "tmux-vendored", "fisher-updated" }) do
    local file = assert(io.open(temp .. "/home with spaces/" .. marker)); file:close()
  end
  os.remove(temp .. "/home with spaces/plugin-enabled")
  put(temp .. "/home with spaces/update-fails", "")
  local result = envy.run(updater, { capture = true, check = false })
  assert(result.exit_code ~= 0, "a failed update must exit nonzero")
  local plugin = assert(io.open(temp .. "/home with spaces/plugin-enabled")); plugin:close()
  assert(result.stdout:find("Update completed with 1 failure(s).", 1, true), "update must summarize failures")
  assert(not result.stdout:find("Update complete.", 1, true), "failed update must not report success")
  os.remove(temp .. "/home with spaces/update-fails")
  os.remove(temp .. "/home with spaces/tmux-vendored")
  os.remove(temp .. "/home with spaces/fisher-updated")
  put(temp .. "/home with spaces/vendor-fails", "")
  result = envy.run(updater, { capture = true, check = false })
  assert(result.exit_code == 1, "failed Envy vendoring must fail the updater")
  assert(not io.open(temp .. "/home with spaces/tmux-vendored"), "failed vendoring must not report success")
  local fisher = assert(io.open(temp .. "/home with spaces/fisher-updated")); fisher:close()
  assert(result.stdout:find("Update completed with 1 failure(s).", 1, true))
  assert(not result.stdout:find("Update complete.", 1, true))
  os.remove(temp .. "/home with spaces/.config/tmux")
  run("mkdir -p " .. quote(temp .. "/home with spaces/.config/tmux"))
  result = envy.run(updater, { capture = true, check = false })
  assert(result.exit_code == 0, "user-owned tmux config must skip Envy vendoring")
  assert(not io.open(temp .. "/home with spaces/tmux-vendored"), "user-owned tmux config must remain untouched")
end)
envy.run = run
run("rm -rf " .. quote(temp))
assert(ok, failure)
print("omp setup tests passed: installation, convergence, failed downloads, and updates")
