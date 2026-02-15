IDENTITY = "local.symlink@r0"

local stale_links = {}

CHECK = function(tmp_dir, opts)
  stale_links = {}
  for _, link in pairs(opts.links) do
    local res = envy.run("readlink " .. link.dest, { capture = true, quiet = true, check = false })
    if res.exit_code ~= 0 or res.stdout:gsub("%s+$", "") ~= link.source then
      table.insert(stale_links, link)
    end
  end
  return #stale_links == 0
end

INSTALL = function(install_dir, stage_dir, fetch_dir, tmp_dir, opts)
  local cmds = {}
  for _, link in pairs(stale_links) do
    local parent = link.dest:match("(.+)/[^/]+$")
    if parent then
      table.insert(cmds, "mkdir -p " .. parent)
    end
    table.insert(cmds, "ln -sfn " .. link.source .. " " .. link.dest)
  end
  return table.concat(cmds, " && ")
end
