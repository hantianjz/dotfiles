-- @envy schema "1"
IDENTITY = "local.uv@r0"
USER_MANAGED = true

local function command_exists(command)
  local res = envy.run("command -v " .. command, {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0
end

local check = function()
  return command_exists("uv")
end

local install = function()
  envy.run("curl -LsSf https://astral.sh/uv/install.sh | sh", { interactive = true })
end

SETUP = { uv = { CHECK = check, INSTALL = install } }
