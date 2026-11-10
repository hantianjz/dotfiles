-- @envy schema "1"
IDENTITY = "local.yazi@r0"
PLATFORMS = { "linux-x86_64", "linux-arm64" }

local version = "26.9.1-1"
local artifacts = {
  x86_64 = { target = "x86_64", sha256 = "331d6247c0a0fd549f14cd599a928a529b8b22eded1bb1f61a518376c7621b45" },
  arm64 = { target = "aarch64", sha256 = "0384a3b7c28ad6aa05ac1bb434dd4e7594051b6be4a1b07d43ca19a86826a315" },
}
local function artifact()
  assert(envy.PLATFORM == "linux", "Yazi deb requires Linux")
  local entry = assert(artifacts[envy.ARCH], "unsupported Yazi deb architecture")
  return "yazi-" .. entry.target .. "-unknown-linux-gnu.deb", entry.sha256
end

-- Both GNU debs depend on file and libc6 >= 2.39, available on Ubuntu 24.04+.
FETCH = function()
  local filename, sha256 = artifact()
  return { source = "https://github.com/sxyazi/yazi/releases/download/v26.9.1/" .. filename, sha256 = sha256 }
end
STAGE = function(fetch_dir, stage_dir)
  local filename = artifact()
  -- Keep the deb intact for apt; automatic archive extraction loses its control metadata.
  envy.copy(fetch_dir .. "/" .. filename, stage_dir .. "/" .. filename)
end

local function quote(value) return string.format("%q", value) end
local function capture(command)
  return envy.run(command, { capture = true, quiet = true, check = false })
end
local function exists(path)
  return capture("test -e " .. quote(path) .. " || test -L " .. quote(path)).exit_code == 0
end
local function native_ready()
  local result = capture("dpkg-query -W -f='${Status}\t${Version}\n' yazi")
  return result.exit_code == 0 and result.stdout:gsub("%s+$", "") == "install ok installed\t" .. version
end
local function cargo_root()
  return os.getenv("CARGO_INSTALL_ROOT") or os.getenv("CARGO_HOME") or assert(os.getenv("HOME")) .. "/.cargo"
end
local function cargo_command()
  local path = assert(os.getenv("HOME")) .. "/.cargo/bin/cargo"
  return capture("test -x " .. quote(path)).exit_code == 0 and quote(path) or "cargo"
end
local function registrations()
  local root = cargo_root()
  if not exists(root .. "/.crates.toml") and not exists(root .. "/.crates2.json") then return {} end
  local result = capture(cargo_command() .. " install --list --root " .. quote(root))
  assert(result.exit_code == 0, "cannot inspect Cargo ownership before Yazi migration")
  local installed = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    local name, installed_version = line:match("^([%w_-]+) v([^%s:]+)")
    if name == "yazi-build" or name == "yazi-fm" or name == "yazi-cli" then
      installed[name] = installed_version
    end
  end
  return installed
end
local function shadows()
  local paths = {}
  local home = assert(os.getenv("HOME"))
  local seen = {}
  for _, directory in ipairs({ cargo_root() .. "/bin", home .. "/.cargo/bin", home .. "/.local/bin", home .. "/bin" }) do
    if not seen[directory] then
      seen[directory] = true
      for _, name in ipairs({ "yazi", "ya" }) do
        local path = directory .. "/" .. name
        if exists(path) and capture("test " .. quote(path) .. " -ef /usr/bin/" .. name).exit_code ~= 0 then
          table.insert(paths, { path = path, name = name, cargo = directory == cargo_root() .. "/bin" })
        end
      end
    end
  end
  return paths
end
local function installer_owned(entry, installed)
  if not entry.cargo or not installed["yazi-build"] then return false end
  -- yazi-build copies these binaries without registering them with Cargo.
  -- A matching version is evidence, not a file receipt: preserve their bytes below.
  local result = capture(quote(entry.path) .. " --version")
  if result.exit_code ~= 0 then return false end
  local title = entry.name == "yazi" and "Yazi" or "Ya"
  local legacy = result.stdout:match("^" .. title .. "%s+([^%s]+)")
  local current = result.stdout:match("^" .. title .. "[\r\n]+%s*Version:%s*([^%s]+)")
  return (current or legacy) == installed["yazi-build"]
end

SETUP = { package = {
  CHECK = function()
    return native_ready() and next(registrations()) == nil and #shadows() == 0
  end,
  INSTALL = function(pkg_dir)
    local installed = registrations()
    local preserved = {}
    -- Resolve ownership before any mutation. Never remove an unknown manual binary.
    for _, entry in ipairs(shadows()) do
      local registered = entry.cargo and installed[entry.name == "yazi" and "yazi-fm" or "yazi-cli"]
      if not registered then
        assert(installer_owned(entry, installed), "manual binary shadows native Yazi; preserve and relocate it explicitly: " .. entry.path)
        table.insert(preserved, entry.path)
      end
    end

    if not native_ready() then
      local filename = artifact()
      envy.run("sudo apt-get install -y --no-install-recommends --allow-downgrades " .. quote(assert(pkg_dir) .. "/" .. filename),
        { interactive = true })
      assert(native_ready(), "apt did not install Yazi " .. version .. "; legacy binaries were preserved")
    end

    -- No legacy mutation happens until apt succeeds and dpkg confirms the exact version.
    if #preserved > 0 then
      local result = envy.run("mktemp -d " .. quote(cargo_root() .. "/.yazi-before-native.XXXXXX"), { capture = true })
      local directory = result.stdout:gsub("%s+$", "")
      for _, path in ipairs(preserved) do
        envy.run("mv " .. quote(path) .. " " .. quote(directory .. "/" .. assert(path:match("([^/]+)$"))))
      end
      print("Preserved unregistered Yazi installer binaries in " .. directory)
    end
    for _, name in ipairs({ "yazi-fm", "yazi-cli", "yazi-build" }) do
      if installed[name] then
        envy.run(cargo_command() .. " uninstall --root " .. quote(cargo_root()) .. " " .. name)
      end
    end
    assert(#shadows() == 0, "legacy binary still shadows native Yazi")
  end,
} }
