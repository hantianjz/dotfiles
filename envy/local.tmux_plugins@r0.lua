-- @envy schema "1"
IDENTITY = "local.tmux_plugins@r0"
USER_MANAGED = true

-- The manifest supplies these packages; selected setup pairs must finish first.
DEPENDENCIES = {
  { spec = "local.symlink@r0", setup = { "links" }, needed_by = "check" },
  { spec = "local.system_packages@r0", setup = { "packages" }, needed_by = "check" },
}

local function quote(value) return string.format("%q", value) end
local function test(expression)
  return envy.run("test " .. expression, { capture = true, quiet = true, check = false }).exit_code == 0
end
local function owns_config(opts)
  if test("-L " .. quote(opts.dest)) and test(quote(opts.dest) .. " -ef " .. quote(opts.source)) then
    return true
  end
  envy.warn("skipping repository tmux plugins: " .. opts.dest .. " is not linked to " .. opts.source ..
    "; existing configuration is preserved. To adopt it, back up and move the destination aside, then rerun setup.")
  return false
end

local function check(pkg_dir, opts)
  if not owns_config(opts) then return true end
  for _, name in ipairs(opts.plugins) do
    if not test("-d " .. quote(opts.dest .. "/plugins/" .. name)) then return false end
  end
  return true
end

local function install(pkg_dir, opts)
  -- Recheck ownership after Envy acquires the setup lock.
  if not owns_config(opts) then return end
  local installer = opts.source .. "/plugins/tpm/bin/install_plugins"
  assert(test("-x " .. quote(installer)),
    "TPM is missing from " .. opts.source .. "; run git submodule update --init --recursive from the dotfiles checkout")
  envy.run(quote(installer))
end

SETUP = { plugins = { CHECK = check, INSTALL = install } }
