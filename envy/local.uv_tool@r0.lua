-- @envy schema "1"
IDENTITY = "local.uv_tool@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.uv@r0",
  source = "local.uv@r0.lua",
  setup = { "uv" },
} }

local missing = {}

local function uv_command()
  local res = envy.run("test -x \"$HOME/.local/bin/uv\"", {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0 and '"${HOME}/.local/bin/uv"' or "uv"
end

local check = function(pkg_dir, opts)
  missing = {}
  -- uv may itself be scheduled for installation by an earlier package.  A
  -- missing executable therefore means all configured tools are missing; it
  -- should not abort Envy while it is still building the install plan.
  local res = envy.run(uv_command() .. " tool list", {
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

  for _, tool in ipairs(opts.tools) do
    if not installed[tool] then
      table.insert(missing, tool)
    end
  end
  return #missing == 0
end

local install = function(pkg_dir, opts)
  local cmds = {}
  for _, tool in ipairs(missing) do
    table.insert(cmds, uv_command() .. " tool install " .. tool)
  end
  return table.concat(cmds, " && ")
end

SETUP = { tools = { CHECK = check, INSTALL = install } }
