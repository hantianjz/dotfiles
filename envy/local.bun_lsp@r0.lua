-- @envy schema "1"
IDENTITY = "local.bun_lsp@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.omp@r0",
  setup = { "tools" },
  needed_by = "check",
} }

local environment = 'export BUN_INSTALL="$HOME/.bun"\nexport PATH="$BUN_INSTALL/bin:$PATH"\n'

SETUP = { servers = {
  CHECK = function()
    return envy.run(environment .. [[
test -x "$BUN_INSTALL/bin/bash-language-server" &&
test -x "$BUN_INSTALL/bin/vscode-json-language-server" &&
test -x "$BUN_INSTALL/bin/typescript-language-server" &&
test -x "$BUN_INSTALL/bin/tsserver" &&
test -x "$BUN_INSTALL/bin/pyright-langserver"
]], { capture = true, quiet = true, check = false }).exit_code == 0
  end,
  INSTALL = function()
    return environment .. [[
set -eu
bun add --global bash-language-server vscode-langservers-extracted typescript-language-server 'typescript@<7' pyright
]]
  end,
} }
