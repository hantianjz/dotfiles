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
  envy.run(quote(root .. "/bin/update"))
  assert(SETUP.tools.CHECK(), "update must refresh the Git-source plugin")
  for _, marker in ipairs({ "bun-updated", "omp-updated" }) do
    local file = assert(io.open(temp .. "/home with spaces/" .. marker)); file:close()
  end
  os.remove(temp .. "/home with spaces/plugin-enabled")
  put(temp .. "/home with spaces/update-fails", "")
  local result = envy.run(quote(root .. "/bin/update"), { capture = true, check = false })
  assert(result.exit_code ~= 0, "a failed update must exit nonzero")
  local plugin = assert(io.open(temp .. "/home with spaces/plugin-enabled")); plugin:close()
  assert(result.stdout:find("Update completed with 1 failure(s).", 1, true), "update must summarize failures")
  assert(not result.stdout:find("Update complete.", 1, true), "failed update must not report success")
  os.remove(temp .. "/home with spaces/update-fails")
  run("mkdir -p " .. quote(temp .. "/home with spaces/.config/tmux/plugins/tpm/bin") .. " " ..
    quote(temp .. "/home with spaces/.config/tmux/plugins/broken/.git") .. " " ..
    quote(temp .. "/home with spaces/.config/tmux/plugins/healthy/.git"))
  put(temp .. "/home with spaces/.config/tmux/plugins/tpm/bin/update_plugins", "#!/bin/sh\nexit 0\n")
  put(temp .. "/bin/git", [[#!/bin/sh
set -eu
case "$3" in
  rev-parse|submodule) : ;;
  pull)
    [ "$2" != "$HOME/.config/tmux/plugins/broken" ] || exit 42
    : > "$HOME/tmux-later-updated" ;;
  *) exit 1 ;;
esac
]])
  run("chmod +x " .. quote(temp .. "/bin/git") .. " " ..
    quote(temp .. "/home with spaces/.config/tmux/plugins/tpm/bin/update_plugins"))
  result = envy.run(quote(root .. "/bin/update"), { capture = true, check = false })
  assert(result.exit_code == 1, "a failed tmux plugin update must fail the updater")
  local later = assert(io.open(temp .. "/home with spaces/tmux-later-updated")); later:close()
  assert(result.stdout:find("Update completed with 1 failure(s).", 1, true))
  -- Real local Git repositories exercise parent updates without moving child pins.
  local git_binary = run("command -v git", { capture = true }).stdout:gsub("%s+$", "")
  local git_prefix = "env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 " .. quote(git_binary) ..
    " -c protocol.file.allow=always -c user.name=Fixture -c user.email=fixture@example.com -C "
  local function git(path, arguments)
    return run(git_prefix .. quote(path) .. " " .. arguments, { capture = true }).stdout:gsub("%s+$", "")
  end
  local seed, parent, project = temp .. "/seed", temp .. "/parent", temp .. "/tmux-root"
  run("mkdir -p " .. quote(seed) .. " " .. quote(parent .. "/bin") .. " " .. quote(project))
  git(seed, "init -b main")
  put(seed .. "/value", "old\n")
  git(seed, "add value"); git(seed, "commit -m old")
  local old_child = git(seed, "rev-parse HEAD")
  git(parent, "init -b main")
  put(parent .. "/bin/update_plugins", "#!/bin/sh\nexit 0\n")
  run("chmod +x " .. quote(parent .. "/bin/update_plugins"))
  git(parent, "submodule add " .. quote(seed) .. " lib/tmux-test")
  git(parent, "add ."); git(parent, "commit -m parent")
  git(project, "init -b main")
  for name, source in pairs({ tpm = parent, tmux = seed, ["tmux-continuum"] = seed }) do
    git(project, "submodule add " .. quote(source) .. " tmux/plugins/" .. name)
  end
  git(project, "commit -am project")
  git(project, "submodule update --init --recursive")
  put(seed .. "/value", "new\n")
  git(seed, "commit -am new")
  local new_child = git(seed, "rev-parse HEAD")
  run("rm -rf " .. quote(temp .. "/home with spaces/.config/tmux/plugins"))
  run("ln -s " .. quote(project .. "/tmux/plugins") .. " " ..
    quote(temp .. "/home with spaces/.config/tmux/plugins"))
  put(temp .. "/bin/git", [[#!/bin/sh
set -eu
source_root=]] .. quote(root) .. "\n" .. [[
if [ "${1:-}" = -C ]; then
  case "${2:-}" in
    "$source_root"|"$source_root"/*)
      destination="$FIXTURES/tmux-root${2#"$source_root"}"
      shift 2
      set -- -C "$destination" "$@" ;;
  esac
fi
if [ "${1:-}" = -C ]; then
  case "$2" in "$FIXTURES"|"$FIXTURES"/*) ;; *) exit 97 ;; esac
else
  case "$PWD" in "$FIXTURES"|"$FIXTURES"/*) ;; *) exit 97 ;; esac
fi
PATH="$FIXTURES/bin:/usr/bin:/bin" exec ]] .. quote(git_binary) .. [[ -c protocol.file.allow=always "$@"
]])
  envy.run(quote(root .. "/bin/update"), { capture = true })
  assert(git(project .. "/tmux/plugins/tpm/lib/tmux-test", "rev-parse HEAD") == old_child,
    "nested submodule must retain its parent's recorded revision")
  assert(git(project .. "/tmux/plugins/tpm", "status --porcelain") == "",
    "updating a parent must not dirty its nested submodule")
  assert(git(project .. "/tmux/plugins/tmux", "rev-parse HEAD") == old_child,
    "theme must retain its recorded release")
  assert(git(project .. "/tmux/plugins/tmux-continuum", "rev-parse HEAD") == new_child,
    "selected parent submodules must follow upstream")
end)
envy.run = run
run("rm -rf " .. quote(temp))
assert(ok, failure)
print("omp setup tests passed: installation, convergence, failed downloads, and updates")
