IDENTITY = "local.brew_package@r0"

DEPENDENCIES = { recipe = "local.brew@r0", source = "local.brew@r0.lua" }

local missing_packages = {}
local missing_tap = {}

CHECK = function(tmp_dir, opts)
  -- Check brew taps
  local res = envy.run("brew tap", { capture = true, quiet = false })
  if res.exit_code ~= 0 then
    return false
  end

  local tapped = {}
  for tap in res.stdout:gmatch("%S+") do
    tapped[tap] = true
  end

  missing_tap = {}

  for _, tap in pairs(opts.taps) do
    if not tapped[tap] then
      table.insert(missing_tap, tap)
    end
  end

  -- Check brew formula/packages

  local res = envy.run("brew list", { capture = true, quiet = false })
  if res.exit_code ~= 0 then
    return false
  end

  local installed = {}
  for pkg in res.stdout:gmatch("%S+") do
    installed[pkg] = true
  end

  missing_packages = {}

  for _, pkg in pairs(opts.packages) do
    if not installed[pkg] then
      table.insert(missing_packages, pkg)
    end
  end

  return #missing_packages == 0 and #missing_tap == 0
end

INSTALL = function(install_dir, stage_dir, fetch_dir, tmp_dir, opts)
  for _, tap in pairs(missing_tap) do
    local res = envy.run("brew tap " .. tap, { capture = true, quiet = false })
    if res.exit_code ~= 0 then
      return false
    end
  end

  return "brew install " .. table.concat(missing_packages, " ")
end
