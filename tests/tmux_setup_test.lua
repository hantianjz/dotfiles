local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(s) return string.format("%q", s) end
local function run(command, check)
  return envy.run(command, { capture = true, quiet = true, check = check ~= false })
end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local function contents(path)
  local file = assert(io.open(path)); local value = file:read("*a"); file:close(); return value
end
local function trim(value) return value:gsub("%s+$", "") end
local bootstrap_cache = os.getenv("ENVY_CACHE_ROOT") or
  (envy.PLATFORM == "darwin" and assert(os.getenv("HOME")) .. "/Library/Caches/envy" or
    (os.getenv("XDG_CACHE_HOME") or assert(os.getenv("HOME")) .. "/.cache") .. "/envy")
local temp = trim(run("mktemp -d /tmp/tmux-setup-test.XXXXXX").stdout)
temp = trim(run("cd " .. quote(temp) .. " && pwd -P").stdout)
local cache = temp .. "/cache"
local ok, failure = pcall(function()
  for _, mode in ipairs({ "fresh", "conflict" }) do
    local base = temp .. "/" .. mode .. " with spaces"
    local home = base .. "/home"
    local dest = home .. "/.config/tmux"
    run("mkdir -p " .. quote(base .. "/envy") .. " " .. quote(base .. "/tmux/plugins") ..
      " " .. quote(base .. "/ai/skills") .. " " .. quote(base .. "/config/herdr") ..
      " " .. quote(home .. "/.config"))
    for _, path in ipairs({ "envy/platform.lua", "envy/tmux.lua", "envy/local.symlink@r0.lua",
        "config/herdr/plugins" }) do
      run("cp " .. quote(root .. "/" .. path) .. " " .. quote(base .. "/" .. path))
    end
    run("cp " .. quote(root .. "/envy.lua") .. " " .. quote(base .. "/actual.lua"))
    put(base .. "/tmux/tmux.conf", "# managed fixture configuration\n")
    put(home .. "/.dotfiles_profile", "personal\n")
    put(home .. "/.gitconfig", "[user]\n\tname = Fixture user\n")
    if mode == "conflict" then
      run("mkdir -p " .. quote(dest .. "/plugins"))
      put(dest .. "/tmux.conf", "# user-owned configuration\n")
      put(dest .. "/plugins/keep", "user-owned plugin\n")
    end

    -- Import the real manifest, but schedule only its GitHub dependencies and
    -- tmux links. The copied manifest ROOT and Envy vendor root must coincide.
    put(base .. "/envy.lua", string.format([[
-- @envy version "0.5.1"
-- @envy bin "bin"
local root = %q
local home = assert(os.getenv("HOME"))
local actual = envy.import(root .. "/actual.lua")
local names = {
  tpm = true, tmux = true, ["tmux-continuum"] = true, ["tmux-sensible"] = true,
  ["tmux-yank"] = true, ["tmux-resurrect"] = true, ["tmux-open-nvim"] = true,
  ["tmux-cpu"] = true,
}
local assets, expected, found = {}, {}, {}
PACKAGES = {}
for _, entry in ipairs(actual.PACKAGES) do
  if entry.spec == "envy.github@r1" then
    local name = entry.options.dest
    assert(names[name] and not found[name], "unexpected or duplicate tmux dependency")
    found[name] = true
    local source = root .. "/" .. entry.vendor .. "/" .. name
    local dest = root .. "/tmux/plugins/" .. name
    expected[dest] = source
    table.insert(assets, { name = name, source = source, dest = dest,
      vendor = root .. "/" .. entry.vendor, ref = entry.options.ref })
    table.insert(PACKAGES, entry)
  end
end
assert(#assets == 8, "all eight tmux repositories must be Envy dependencies")
local links = {}
for _, entry in ipairs(actual.PACKAGES) do
  if entry.spec == "local.symlink@r0" then
    for _, link in ipairs(entry.options.links) do
      if link.dest == home .. "/.config/tmux" then
        assert(link.source == root .. "/tmux", "tmux configuration must use fixture ROOT")
        table.insert(links, link)
      elseif link.dest:sub(1, #(root .. "/tmux/plugins/")) == root .. "/tmux/plugins/" then
        assert(expected[link.dest] == link.source, "plugin link must target its vendored dependency")
        expected[link.dest] = nil
        table.insert(links, link)
      end
    end
    entry.options.links = links
    table.insert(PACKAGES, entry)
  end
end
assert(#links == 9 and next(expected) == nil, "configuration and all eight source links are required")
local data = assert(io.open(root .. "/assets.lua", "w"))
data:write("return {\n")
for _, asset in ipairs(assets) do
  data:write(string.format("{name=%%q,source=%%q,dest=%%q,vendor=%%q,ref=%%q},\n",
    asset.name, asset.source, asset.dest, asset.vendor, asset.ref))
end
assert(data:write("}\n")); assert(data:close())
]], base))
    -- The bootstrap may borrow only its already-pinned binary from the original
    -- cache. All package installs, vendor data, links and profile data stay here.
    local command = "ENVY_CACHE_ROOT=" .. quote(bootstrap_cache) .. " HOME=" .. quote(home) ..
      " XDG_CONFIG_HOME=" .. quote(home .. "/.config") .. " XDG_CACHE_HOME=" .. quote(home .. "/.cache") ..
      " XDG_DATA_HOME=" .. quote(home .. "/.local/share") .. " DOTFILES_PROFILE=personal" ..
      " GIT_CONFIG_GLOBAL=" .. quote(home .. "/.gitconfig") .. " GIT_CONFIG_SYSTEM=/dev/null " ..
      quote(root .. "/bin/envy") .. " --project " .. quote(base) .. " --cache-root " .. quote(cache)
    local install = command .. " install --manifest " .. quote(base .. "/envy.lua")
    local vendor = command .. " vendor --all --manifest " .. quote(base .. "/envy.lua")
    local result = run(install)
    run(vendor)
    local assets = assert(loadfile(base .. "/assets.lua"))()
    local function verify_assets()
      for _, asset in ipairs(assets) do
        assert(trim(run("readlink " .. quote(asset.dest)).stdout) == asset.source,
          asset.name .. " must link to its managed vendor source")
        assert(trim(run("git -C " .. quote(asset.source) .. " rev-parse HEAD").stdout) == asset.ref,
          asset.name .. " must retain its manifest revision")
        run("test -d " .. quote(asset.dest))
        run("git -C " .. quote(asset.source) .. " diff --exit-code HEAD --")
      end
      assert(contents(home .. "/.dotfiles_profile") == "personal\n")
      assert(contents(home .. "/.gitconfig") == "[user]\n\tname = Fixture user\n")
    end
    verify_assets()
    if mode == "conflict" then
      assert(contents(dest .. "/tmux.conf") == "# user-owned configuration\n")
      assert(contents(dest .. "/plugins/keep") == "user-owned plugin\n")
      run("test ! -L " .. quote(dest))
      assert((result.stderr or ""):find(dest, 1, true), "preserved configuration must be reported")
    else
      assert(trim(run("readlink " .. quote(dest)).stdout) == base .. "/tmux")
      assert(contents(dest .. "/tmux.conf") == "# managed fixture configuration\n")

      run(install)
      run(vendor)
      verify_assets()

      local missing, edited = assets[1], assets[2]
      local tracked = assert(run("git -C " .. quote(edited.source) .. " ls-files").stdout:match("[^\r\n]+"))
      local edited_path = edited.source .. "/" .. tracked
      local original = contents(edited_path)
      run("rm -rf " .. quote(missing.vendor))
      run("test ! -e " .. quote(missing.dest))
      run(vendor)
      verify_assets()
      put(edited_path, original .. "\n# edited managed vendor data\n")
      run(vendor)
      assert(contents(edited_path) == original, "edited managed vendor data must be restored")
      verify_assets()
    end
  end
end)
run("rm -rf " .. quote(temp))
assert(ok, failure)
print("tmux dependency tests passed: eight pinned vendors and source links, convergence, restoration, and preserved user configuration")
