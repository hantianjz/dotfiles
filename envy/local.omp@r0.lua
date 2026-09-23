-- @envy schema "1"
IDENTITY = "local.omp@r0"
USER_MANAGED = true

DEPENDENCIES = {
  { spec = "local.system_packages@r0", setup = { "packages" }, needed_by = "check" },
}

-- Include fresh installations before invoking installers or the plugin manager.
-- Bun's installer also avoids rewriting shell configuration when bun is on PATH.
local environment = 'export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"\n'

local function check()
  return envy.run(environment .. [[
command -v bun >/dev/null 2>&1 &&
omp plugin list --json | jq -e '.npm[] | select(.name == "omp-ponytail-caveman" and .enabled)' >/dev/null
]], { capture = true, quiet = true, check = false }).exit_code == 0
end

local function install()
  return environment .. [[
set -eu
set -o pipefail
if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | BUN_INSTALL="$HOME/.bun" bash
fi
if ! command -v omp >/dev/null 2>&1; then
  curl -fsSL https://omp.sh/install.sh | PI_INSTALL_DIR="$HOME/.local/bin" sh -s -- --binary
fi
omp plugin install github:phenome/omp-ponytail-caveman
]]
end

SETUP = { tools = { CHECK = check, INSTALL = install } }
