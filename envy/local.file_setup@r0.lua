-- @envy schema "1"
IDENTITY = "local.file_setup@r0"
USER_MANAGED = true

local missing = {}

local check = function(pkg_dir, opts)
  missing = {}
  for _, path in ipairs(opts.paths) do
    local is_dir = path:sub(-1) == "/"
    local flag = is_dir and "-d" or "-f"
    local res = envy.run("test " .. flag .. " " .. path, { capture = true, quiet = true, check = false })
    if res.exit_code ~= 0 then
      table.insert(missing, path)
    end
  end
  return #missing == 0
end

local install = function(pkg_dir, opts)
  local cmds = {}
  for _, path in ipairs(missing) do
    if path:sub(-1) == "/" then
      table.insert(cmds, "mkdir -p " .. path)
    else
      local parent = path:match("(.+)/[^/]+$")
      if parent then
        table.insert(cmds, "mkdir -p " .. parent .. " && touch " .. path)
      else
        table.insert(cmds, "touch " .. path)
      end
    end
  end
  return table.concat(cmds, " && ")
end

SETUP = { files = { CHECK = check, INSTALL = install } }
