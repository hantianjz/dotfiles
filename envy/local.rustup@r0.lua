-- @envy schema "1"
IDENTITY = "local.rustup@r0"
USER_MANAGED = true

local check = function(pkg_dir, opts)
  local res = envy.run("rustup --version", { capture = true, quiet = true })
  return res.exit_code == 0
end

local install = function(pkg_dir, opts)
  return "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
end

SETUP = { rustup = { CHECK = check, INSTALL = install } }
