-- @envy schema "1"
IDENTITY = "local.binstall_tools@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.binstall@r0",
  source = "local.binstall@r0.lua",
  setup = { "tools" },
  needed_by = "check",
} }

local function command(opts, mode)
  assert(type(opts.script) == "string" and opts.script:sub(1, 1) == "/", "rust-tools script must be absolute")
  return "bash " .. string.format("%q", opts.script) .. " " .. mode
end

SETUP = { tools = {
  CHECK = function(_, opts)
    return envy.run(command(opts, "check"), { capture = true, quiet = true, check = false }).exit_code == 0
  end,
  INSTALL = function(_, opts)
    return command(opts, "install")
  end,
} }
