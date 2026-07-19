-- @envy schema "1"
IDENTITY = "local.symlink@r0"
USER_MANAGED = true

local stale_links = {}

local function quote(path)
  return string.format("%q", path)
end

local function run_test(expression)
  local res = envy.run(expression, { capture = true, quiet = true, check = false })
  return res.exit_code == 0
end

local function warn_conflict(link)
  local nested = link.dest .. "/" .. link.source:match("([^/]+)$")
  local suffix = ""
  if run_test("test -L " .. quote(nested)) then
    suffix = "; an older run may have created the nested link " .. nested
  end
  envy.warn("preserving existing non-symlink destination " .. link.dest ..
    " (wanted " .. link.source .. ")" .. suffix)
end

local check = function(pkg_dir, opts)
  stale_links = {}
  for _, link in ipairs(opts.links) do
    if run_test("test -L " .. quote(link.dest)) then
      local res = envy.run("readlink " .. quote(link.dest), {
        capture = true,
        quiet = true,
        check = false,
      })
      if res.exit_code ~= 0 or res.stdout:gsub("%s+$", "") ~= link.source then
        table.insert(stale_links, link)
      end
    elseif run_test("test -e " .. quote(link.dest)) then
      warn_conflict(link)
    else
      table.insert(stale_links, link)
    end
  end
  return #stale_links == 0
end

local install = function(pkg_dir, opts)
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

SETUP = { links = { CHECK = check, INSTALL = install } }
