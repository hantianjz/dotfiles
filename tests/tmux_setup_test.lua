local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(s) return string.format("%q", s) end
local function run(command, check)
  return envy.run(command, { capture = true, quiet = true, check = check ~= false })
end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local function contents(path)
  local file = assert(io.open(path)); local value = file:read("*a"); file:close(); return value
end
local temp = run("mktemp -d /tmp/tmux-setup-test.XXXXXX").stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  -- Harmless stand-in for the native package manager; the real Envy scheduler
  -- must complete it and the real symlink recipe before the plugin installer.
  put(temp .. "/system.lua", [[
IDENTITY = "local.system_packages@r0"
USER_MANAGED = true
SETUP = { packages = {
  CHECK = function(_, opts)
    local file = io.open(opts.ready)
    if file then file:close(); return true end
    return false
  end,
  INSTALL = function(_, opts)
    local file = assert(io.open(opts.ready, "w")); file:write("ready"); file:close()
  end,
} }
]])
  for _, mode in ipairs({ "conflict", "adopt", "missing-tpm", "installer-error" }) do
    local base = temp .. "/" .. mode .. " with spaces"
    local source, dest = base .. "/source", base .. "/home/.config/tmux"
    run("mkdir -p " .. quote(source .. "/plugins/tpm/bin") .. " " .. quote(base .. "/home/.config"))
    local ready, calls = base .. "/ready", base .. "/installer-calls"
    if mode ~= "missing-tpm" then
      put(source .. "/plugins/tpm/bin/install_plugins", table.concat({
        "#!/bin/sh", "set -eu", "test -f " .. quote(ready),
        "test -L " .. quote(dest), "test " .. quote(dest) .. " -ef " .. quote(source),
        "printf 'called\\n' >> " .. quote(calls),
        mode == "installer-error" and "exit 42" or "mkdir -p " .. quote(dest .. "/plugins/example"), "",
      }, "\n"))
      run("chmod +x " .. quote(source .. "/plugins/tpm/bin/install_plugins"))
    end
    if mode == "conflict" then
      run("mkdir " .. quote(dest))
      put(dest .. "/tmux.conf", "# user-owned configuration\n")
    end
    local manifest = base .. "/envy.lua"
    put(manifest, string.format([[
-- @envy bin "bin"
PACKAGES = {
  { spec = "local.tmux_plugins@r0", source = %q, setup = { "plugins" },
    options = { source = %q, dest = %q, plugins = { "example" } } },
  { spec = "local.system_packages@r0", source = %q, options = { ready = %q } },
  { spec = "local.symlink@r0", source = %q,
    options = { links = { { source = %q, dest = %q } } } },
}
]], root .. "/envy/local.tmux_plugins@r0.lua", source, dest, temp .. "/system.lua", ready,
      root .. "/envy/local.symlink@r0.lua", source, dest))
    local command = quote(root .. "/bin/envy") .. " --cache-root " .. quote(temp .. "/cache") ..
      " install --manifest " .. quote(manifest)
    local result = run(command, false)
    if mode == "conflict" then
      assert(result.exit_code == 0, result.stderr)
      assert(contents(dest .. "/tmux.conf") == "# user-owned configuration\n")
      run("test ! -L " .. quote(dest) .. " && test ! -e " .. quote(calls))
      assert((result.stderr or ""):find(dest, 1, true), "the preserved destination must be reported")
    elseif mode == "adopt" then
      assert(result.exit_code == 0, result.stderr)
      run("test -d " .. quote(dest .. "/plugins/example"))
      assert(contents(calls) == "called\n")
      run(command)
      assert(contents(calls) == "called\n", "satisfied plugins must not be reinstalled")
    else
      assert(result.exit_code ~= 0, "owned-config installation errors must propagate")
      run("test -L " .. quote(dest) .. " && test ! -d " .. quote(dest .. "/plugins/example"))
      if mode == "installer-error" then assert(contents(calls) == "called\n") end
    end
  end
end)
run("rm -rf " .. quote(temp))
assert(ok, failure)
print("tmux setup tests passed: preserved conflicts, ordered prerequisites, installation, idempotency, and actionable installation failures")
