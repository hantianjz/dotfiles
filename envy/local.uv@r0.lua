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
  if envy.PLATFORM == "darwin" then
    return "brew install uv"
  elseif command_exists("pacman") then
    return "sudo pacman -S --needed --noconfirm uv"
  elseif command_exists("apt-get") then
    -- uv is not available in all supported apt repositories.
    return "curl -LsSf https://astral.sh/uv/install.sh | sh"
  end

  error("local.uv@r0 requires brew, pacman, or apt-get")
end

SETUP = { uv = { CHECK = check, INSTALL = install } }
