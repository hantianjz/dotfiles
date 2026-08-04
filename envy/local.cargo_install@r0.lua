-- @envy schema "1"
IDENTITY = "local.cargo_install@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.rustup_toolchain@r0",
  source = "local.rustup_toolchain@r0.lua",
  setup = { "toolchain" },
  options = { toolchain = "stable" },
} }

local missing = {}

local function cargo_command()
  local res = envy.run("test -x \"$HOME/.cargo/bin/cargo\"", {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0 and '"${HOME}/.cargo/bin/cargo"' or "cargo"
end

local check = function(pkg_dir, opts)
  missing = {}
  local res = envy.run(cargo_command() .. " install --list", {
    capture = true,
    quiet = true,
    check = false,
  })
  local installed = {}
  if res.exit_code == 0 then
    for name in res.stdout:gmatch("(%S+) v%S+") do
      installed[name] = true
    end
  end

  for _, crate in ipairs(opts.crates) do
    local name = crate.name or crate.package or crate.repo:match(".+/(.+)$")
    name = name:gsub("%.git$", "")
    if not installed[name] then
      table.insert(missing, crate)
    end
  end
  return #missing == 0
end

local install = function(pkg_dir, opts)
  local cmds = {}
  for _, crate in ipairs(missing) do
    if crate.repo then
      table.insert(cmds, cargo_command() .. " install --git " .. string.format("%q", crate.repo))
    else
      local command = cargo_command() .. " install --locked " .. crate.package
      if crate.force then
        command = cargo_command() .. " install --force --locked " .. crate.package
      end
      if crate.version then
        command = command .. " --version " .. crate.version
      end
      table.insert(cmds, command)
    end
  end
  return table.concat(cmds, " && ")
end

SETUP = { crates = { CHECK = check, INSTALL = install } }
