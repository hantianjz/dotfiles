IDENTITY = "local.ai_skills_symlink@r0"

local stale_links = {}

local function quote(path)
  return string.format("%q", path)
end

local function trim_trailing_space(value)
  return value:gsub("%s+$", "")
end

local function list_skill_names(source_dir)
  local names = {}
  local cmd = "find " .. quote(source_dir) .. " -mindepth 1 -maxdepth 1 -type d"
  local handle = io.popen(cmd)
  if not handle then
    return names
  end

  for line in handle:lines() do
    local normalized = line:gsub("/+$", "")
    local skill = normalized:match("([^/]+)$")
    if skill then
      table.insert(names, skill)
    end
  end

  handle:close()
  table.sort(names)
  return names
end

local function build_links(opts)
  local links = {}
  for _, skill in ipairs(list_skill_names(opts.source_dir)) do
    local source = opts.source_dir .. "/" .. skill
    for _, dest_root in ipairs(opts.dest_roots) do
      table.insert(links, { source = source, dest = dest_root .. "/" .. skill })
    end
  end
  return links
end

CHECK = function(tmp_dir, opts)
  stale_links = {}

  for _, link in ipairs(build_links(opts)) do
    local res = envy.run("readlink " .. quote(link.dest), { capture = true, quiet = true, check = false })
    if res.exit_code ~= 0 or trim_trailing_space(res.stdout) ~= link.source then
      table.insert(stale_links, link)
    end
  end

  return #stale_links == 0
end

INSTALL = function(install_dir, stage_dir, fetch_dir, tmp_dir, opts)
  local cmds = {}

  for _, link in ipairs(stale_links) do
    local parent = link.dest:match("(.+)/[^/]+$")
    if parent then
      table.insert(cmds, "mkdir -p " .. quote(parent))
    end
    table.insert(cmds, "ln -sfn " .. quote(link.source) .. " " .. quote(link.dest))
  end

  return table.concat(cmds, " && ")
end
