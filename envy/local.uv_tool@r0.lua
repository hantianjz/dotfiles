IDENTITY = "local.uv_tool@r0"

local missing = {}

CHECK = function(tmp_dir, opts)
  missing = {}
  local res = envy.run("uv tool list", { capture = true, quiet = true })
  local installed = {}
  if res.exit_code == 0 then
    for name in res.stdout:gmatch("(%S+) v%S+") do
      installed[name] = true
    end
  end

  for _, tool in ipairs(opts.tools) do
    if not installed[tool] then
      table.insert(missing, tool)
    end
  end
  return #missing == 0
end

INSTALL = function(install_dir, stage_dir, fetch_dir, tmp_dir, opts)
  local cmds = {}
  for _, tool in ipairs(missing) do
    table.insert(cmds, "uv tool install " .. tool)
  end
  return table.concat(cmds, " && ")
end
