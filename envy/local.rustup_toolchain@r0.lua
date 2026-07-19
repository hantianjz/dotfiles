-- @envy schema "1"
IDENTITY = "local.rustup_toolchain@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.rustup@r0",
  source = "local.rustup@r0.lua",
  setup = { "rustup" },
} }

local check = function(pkg_dir, opts)
  local res = envy.run("rustup default", { capture = true, quiet = true })
  if res.exit_code ~= 0 then
    return false
  end
  return res.stdout:match("^" .. opts.toolchain) ~= nil
end

local install = function(pkg_dir, opts)
  return "rustup default " .. opts.toolchain
end

SETUP = { toolchain = { CHECK = check, INSTALL = install } }
