-- @envy schema "1"
IDENTITY = "local.rustup_toolchain@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.rustup@r0",
  source = "local.rustup@r0.lua",
  setup = { "rustup" },
} }

local function rustup_command()
  local res = envy.run("test -x \"$HOME/.cargo/bin/rustup\"", {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0 and '"${HOME}/.cargo/bin/rustup"' or "rustup"
end

local check = function(pkg_dir, opts)
  local res = envy.run(rustup_command() .. " default", {
    capture = true,
    quiet = true,
    check = false,
  })
  if res.exit_code ~= 0 then
    return false
  end
  return res.stdout:match("^" .. opts.toolchain) ~= nil
end

local install = function(pkg_dir, opts)
  return rustup_command() .. " default " .. opts.toolchain
end

SETUP = { toolchain = { CHECK = check, INSTALL = install } }
