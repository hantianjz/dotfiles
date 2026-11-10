-- @envy schema "1"
IDENTITY = "local.tmx@r0"

local artifacts = {
  ["darwin-arm64"] = { "tmx_Darwin_arm64.tar.gz", "2c418d9bd5edf7a678ebc02506dbe0e3f6b57484d029f798c45dc5dc9031ecab" },
  ["darwin-x86_64"] = { "tmx_Darwin_x86_64.tar.gz", "f7dfcb6a246bdfbf774a010033a5dfe2474e3bb1c480b39326b504d132e52dff" },
  ["linux-arm64"] = { "tmx_Linux_arm64.tar.gz", "7416f62421fab40d77ec92f7ca47ca0d367d7a1871ae58efe94ff3d1a85c94ac" },
  ["linux-x86_64"] = { "tmx_Linux_x86_64.tar.gz", "18f4a5c9e8c2f90454ed4e7fb07b6ab116a6d2c24c73023e36042fb3ee8f9e3a" },
}

FETCH = function()
  local artifact = assert(artifacts[envy.PLATFORM_ARCH], "unsupported tmx release platform")
  return { source = "https://github.com/hantianjz/tmx/releases/download/v0.0.8/" .. artifact[1], sha256 = artifact[2] }
end
STAGE = { strip = 0 }

local function quote(value) return string.format("%q", value) end
local function capture(command)
  return envy.run(command, { capture = true, quiet = true, check = false })
end
local function cargo_root()
  return os.getenv("CARGO_INSTALL_ROOT") or os.getenv("CARGO_HOME") or assert(os.getenv("HOME")) .. "/.cargo"
end
local function cargo_command()
  local path = assert(os.getenv("HOME")) .. "/.cargo/bin/cargo"
  return capture("test -x " .. quote(path)).exit_code == 0 and quote(path) or "cargo"
end
local function legacy_owned()
  local root = cargo_root()
  if capture("test -f " .. quote(root .. "/.crates.toml") .. " || test -f " .. quote(root .. "/.crates2.json")).exit_code ~= 0 then
    return false
  end
  local result = capture(cargo_command() .. " install --list --root " .. quote(root))
  assert(result.exit_code == 0, "cannot inspect Cargo ownership before tmx migration")
  for line in result.stdout:gmatch("[^\r\n]+") do
    local source = line:match("^tmx v[^%s]+ %(([^%)]+)%)")
    if source then
      local repo = source:match("^[^?#]+")
      return repo:gsub("^git%+", ""):gsub("%.git$", "") == "https://github.com/hantianjz/tmx"
    end
  end
  return false
end

SETUP = { tools = {
  CHECK = function(pkg_dir)
    for _, binary in ipairs({ "tmx", "hmx" }) do
      local destination = assert(os.getenv("HOME")) .. "/.local/bin/" .. binary
      if capture("test -x " .. quote(destination) .. " && cmp -s " .. quote(pkg_dir .. "/" .. binary) ..
          " " .. quote(destination)).exit_code ~= 0 then return false end
    end
    return not legacy_owned()
  end,
  INSTALL = function(pkg_dir)
    local uninstall = legacy_owned() and
      (cargo_command() .. " uninstall --root " .. quote(cargo_root()) .. " tmx") or ":"
    -- Stage both files before removing Cargo ownership, including overlapping install roots.
    return string.format([[
set -eu
install -d "$HOME/.local/bin"
work=$(mktemp -d "$HOME/.local/bin/.tmx.XXXXXX")
trap 'rm -rf "$work"' EXIT
install -m 755 %s "$work/tmx"
install -m 755 %s "$work/hmx"
%s
mv "$work/tmx" "$HOME/.local/bin/tmx"
mv "$work/hmx" "$HOME/.local/bin/hmx"
]], quote(pkg_dir .. "/tmx"), quote(pkg_dir .. "/hmx"), uninstall)
  end,
} }
