-- @envy schema "1"
IDENTITY = "local.apt@r0"
USER_MANAGED = true

local missing_packages = {}

local function require_apt()
  for _, command in ipairs({ "apt-get", "dpkg-query" }) do
    local res = envy.run("command -v " .. command, {
      capture = true,
      quiet = true,
      check = false,
    })
    if res.exit_code ~= 0 then
      error("local.apt@r0 requires " .. command .. " but it is not available")
    end
  end
end

local check = function(pkg_dir, opts)
  require_apt()

  local cmd = "dpkg-query -W -f='${Package}\n' " .. table.concat(opts.packages, " ")
  local res = envy.run(cmd, { capture = true, quiet = true, check = false })

  local installed = {}

  for line in res.stdout:gmatch("[^\r\n]+") do
    local pkg = line:match("^%S+")
    if pkg then
      installed[pkg] = true
    end
  end

  missing_packages = {}

  for _, pkg in ipairs(opts.packages) do
    if not installed[pkg] then
      table.insert(missing_packages, pkg)
    end
  end

  return #missing_packages == 0
end

local install = function(pkg_dir, opts)
  require_apt()
  return "sudo apt-get install -y " .. table.concat(missing_packages, " ")
end

SETUP = { packages = { CHECK = check, INSTALL = install } }
