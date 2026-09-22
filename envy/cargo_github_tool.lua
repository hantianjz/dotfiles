local M = {}

local function quote(value)
  return string.format("%q", value)
end

local function cargo_command()
  local res = envy.run("test -x \"$HOME/.cargo/bin/cargo\"", {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0 and '"${HOME}/.cargo/bin/cargo"' or "cargo"
end

local function installed(package)
  local res = envy.run(cargo_command() .. " install --list", {
    capture = true,
    quiet = true,
    check = false,
  })
  if res.exit_code ~= 0 then
    return false
  end
  for name in res.stdout:gmatch("(%S+) v%S+") do
    if name == package then
      return true
    end
  end
  return false
end

function M.setup(package, source_dir)
  local missing = false
  return {
    CHECK = function()
      missing = not installed(package)
      return not missing
    end,
    INSTALL = function()
      if not missing then
        return
      end
      local source = envy.package("envy.github@r0") .. "/" .. source_dir
      envy.run(cargo_command() .. " install --path " .. quote(source) .. " --locked")
    end,
  }
end

return M
