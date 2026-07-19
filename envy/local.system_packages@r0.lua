-- @envy schema "1"
IDENTITY = "local.system_packages@r0"
USER_MANAGED = true

local missing_packages = {}
local missing_casks = {}
local missing_taps = {}

local function command_exists(command)
  local res = envy.run("command -v " .. command, {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0
end

local function words(output)
  local result = {}
  for value in output:gmatch("%S+") do
    result[value] = true
  end
  return result
end

local function missing(wanted, installed)
  local result = {}
  for _, value in ipairs(wanted or {}) do
    if not installed[value] then
      table.insert(result, value)
    end
  end
  return result
end

local function capture(command)
  local res = envy.run(command, { capture = true, quiet = true, check = false })
  if res.exit_code ~= 0 then
    return {}
  end
  return words(res.stdout)
end

local check = function(pkg_dir, opts)
  if not command_exists(opts.manager == "apt" and "apt-get" or opts.manager) then
    return false
  end

  if opts.manager == "brew" then
    missing_packages = missing(opts.packages, capture("brew list --formula -1"))
    missing_casks = missing(opts.casks, capture("brew list --cask -1"))
    missing_taps = missing(opts.taps, capture("brew tap"))
  elseif opts.manager == "apt" then
    local command = "dpkg-query -W -f='${Package}\\n' " .. table.concat(opts.packages, " ")
    missing_packages = missing(opts.packages, capture(command))
    missing_casks = {}
    missing_taps = {}
  elseif opts.manager == "pacman" then
    missing_packages = missing(opts.packages, capture("pacman -Qq"))
    missing_casks = {}
    missing_taps = {}
  else
    error("unsupported system package manager: " .. tostring(opts.manager))
  end

  return #missing_packages == 0 and #missing_casks == 0 and #missing_taps == 0
end

local function run_interactive(command)
  envy.run(command, { interactive = true })
end

local install = function(pkg_dir, opts)
  local manager_command = opts.manager == "apt" and "apt-get" or opts.manager
  if not command_exists(manager_command) then
    error("required system package manager is unavailable: " .. manager_command)
  end

  if opts.manager == "brew" then
    for _, tap in ipairs(missing_taps) do
      run_interactive("brew tap " .. tap)
    end
    if #missing_packages > 0 then
      run_interactive("brew install " .. table.concat(missing_packages, " "))
    end
    if #missing_casks > 0 then
      run_interactive("brew install --cask " .. table.concat(missing_casks, " "))
    end
  elseif opts.manager == "apt" then
    run_interactive("sudo apt-get update")
    run_interactive("sudo apt-get install -y " .. table.concat(missing_packages, " "))
  elseif opts.manager == "pacman" then
    run_interactive("sudo pacman -S --needed --noconfirm " .. table.concat(missing_packages, " "))
  end
end

SETUP = { packages = { CHECK = check, INSTALL = install } }
