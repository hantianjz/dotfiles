-- @envy schema "1"
IDENTITY = "local.cargo_install@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.rustup_toolchain@r0",
  source = "local.rustup_toolchain@r0.lua",
  setup = { "toolchain" },
} }

local missing = {}

local check = function(pkg_dir, opts)
  missing = {}
  local res = envy.run("cargo install --list", { capture = true, quiet = true })
  local installed = {}
  if res.exit_code == 0 then
    for name in res.stdout:gmatch("(%S+) v%S+") do
      installed[name] = true
    end
  end

  for _, crate in ipairs(opts.crates) do
    local name = crate.name or crate.repo:match(".+/(.+)$")
    if not installed[name] then
      table.insert(missing, crate.repo)
    end
  end
  return #missing == 0
end

local install = function(pkg_dir, opts)
  local cmds = {}
  for _, repo in ipairs(missing) do
    table.insert(cmds, "cargo install --git " .. repo)
  end
  return table.concat(cmds, " && ")
end

SETUP = { crates = { CHECK = check, INSTALL = install } }
