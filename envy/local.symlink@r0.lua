-- @envy schema "1"
IDENTITY = "local.symlink@r0"
USER_MANAGED = true

local stale_links = {}
local retired_links = {}

local function quote(path)
  return string.format("%q", path)
end

local function run_test(expression)
  local res = envy.run(expression, { capture = true, quiet = true, check = false })
  return res.exit_code == 0
end

local function link_source(path)
  local res = envy.run("readlink " .. quote(path), { capture = true, quiet = true, check = false })
  if res.exit_code == 0 then
    return res.stdout:gsub("\n$", "")
  end
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
  retired_links = {}
  for _, link in ipairs(opts.links) do
    if run_test("test -L " .. quote(link.dest)) then
      if link_source(link.dest) ~= link.source then
        table.insert(stale_links, link)
      end
    elseif run_test("test -e " .. quote(link.dest)) then
      if run_test("test -f " .. quote(link.source) .. " && test -f " .. quote(link.dest) ..
          " && cmp -s " .. quote(link.source) .. " " .. quote(link.dest)) then
        -- A copied file with identical contents is safe to adopt as a managed
        -- symlink. Different user-owned files and directories stay untouched.
        table.insert(stale_links, link)
      else
        warn_conflict(link)
      end
    else
      table.insert(stale_links, link)
    end
  end
  for _, link in ipairs(opts.retired_links or {}) do
    if link_source(link.dest) == link.source then
      table.insert(retired_links, link)
    end
  end
  return #stale_links == 0 and #retired_links == 0
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
  for _, link in ipairs(retired_links) do
    local path = quote(link.dest)
    table.insert(cmds, "if [ \"$(readlink " .. path .. " 2>/dev/null)\" = " .. quote(link.source) ..
      " ]; then rm -f " .. path .. "; fi")
  end
  return table.concat(cmds, " && ")
end

SETUP = { links = { CHECK = check, INSTALL = install } }
