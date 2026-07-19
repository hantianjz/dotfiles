-- @envy schema "1"
IDENTITY = "local.pacman@r0"
USER_MANAGED = true

local missing_packages = {}

local function require_pacman()
  local res = envy.run("command -v pacman", {
    capture = true,
    quiet = true,
    check = false,
  })
  if res.exit_code ~= 0 then
    error("local.pacman@r0 requires pacman but it is not available")
  end
end

local check = function(pkg_dir, opts)
  require_pacman()

  local res = envy.run("pacman -Qq", {
    capture = true,
    quiet = true,
  })

  local installed = {}
  for package in res.stdout:gmatch("[^\r\n]+") do
    installed[package] = true
  end

  missing_packages = {}
  for _, package in ipairs(opts.packages) do
    if not installed[package] then
      table.insert(missing_packages, package)
    end
  end

  return #missing_packages == 0
end

local install = function(pkg_dir, opts)
  require_pacman()
  return "sudo pacman -S --needed --noconfirm " .. table.concat(missing_packages, " ")
end

SETUP = { packages = { CHECK = check, INSTALL = install } }
