-- envy.lua - Project manifest
-- @envy version "0.0.64"
-- @envy bin "bin"
-- @envy deploy "true"

local MANIFEST = debug.getinfo(1, "S").source:sub(2)
local ROOT = MANIFEST:match("(.*)/") or "."
if ROOT:sub(1, 1) ~= "/" then
  local cwd = assert(os.getenv("PWD"), "PWD is not set")
  ROOT = ROOT == "." and cwd or cwd .. "/" .. ROOT
end
local HOME = assert(os.getenv("HOME"), "HOME is not set")
local TMUX_PLUGIN_DIR = HOME .. "/.config/tmux/plugins"
local platform = dofile(ROOT .. "/envy/platform.lua")

PACKAGES = {}

local function quote(value)
  return string.format("%q", value)
end

local function command_exists(command)
  local res = envy.run("command -v " .. command, {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0
end

local PROFILE, PACKAGE_MANAGER = platform.detect(envy.PLATFORM, command_exists)
local PACKAGE_PROFILE = platform.packages(PROFILE, PACKAGE_MANAGER)

envy.extend(PACKAGES, { {
  spec = "local.file_setup@r0",
  source = "envy/local.file_setup@r0.lua",
  setup = { "files" },
  options = {
    paths = {
      HOME .. "/bin/",
      HOME .. "/.vim/backup/",
      HOME .. "/.gitconfig_local",
      HOME .. "/.config/local_config.fish",
    },
  },
} })

local SYMLINKS = {
  { source = ROOT .. "/fish",                       dest = HOME .. "/.config/fish" },
  { source = ROOT .. "/shellrc/bashrc",             dest = HOME .. "/.bashrc" },
  { source = ROOT .. "/shellrc/profile",            dest = HOME .. "/.profile" },
  { source = ROOT .. "/nvim",                       dest = HOME .. "/.config/nvim" },
  { source = ROOT .. "/config/gitconfig",           dest = HOME .. "/.gitconfig" },
  { source = ROOT .. "/config/gitignore",           dest = HOME .. "/.gitignore" },
  { source = ROOT .. "/config/ghostty",             dest = HOME .. "/.config/ghostty" },
  { source = ROOT .. "/config/herdr/config.toml",   dest = HOME .. "/.config/herdr/config.toml" },
  { source = ROOT .. "/scripts/herdr-tmux-action",   dest = HOME .. "/.config/herdr/herdr-tmux-action" },
  { source = ROOT .. "/tmux",                       dest = HOME .. "/.config/tmux" },
  { source = ROOT .. "/config/gdbinit",             dest = HOME .. "/.gdbinit" },
  { source = ROOT .. "/scripts/batch_find_replace", dest = HOME .. "/bin/batch_find_replace" },
  { source = ROOT .. "/scripts/find_replace",       dest = HOME .. "/bin/find_replace" },
  { source = ROOT .. "/scripts/grb",                dest = HOME .. "/bin/grb" },
  { source = ROOT .. "/scripts/gprune",             dest = HOME .. "/bin/gprune" },
  { source = ROOT .. "/scripts/usb",                dest = HOME .. "/bin/usb" },
}

envy.extend(SYMLINKS, platform.desktop_links(PROFILE, ROOT, HOME))

local skills = envy.run("find " .. quote(ROOT .. "/ai/skills") .. " -mindepth 1 -maxdepth 1 -type d", {
  capture = true,
  quiet = true,
  check = false,
})
if skills.exit_code == 0 then
  for source in skills.stdout:gmatch("[^\r\n]+") do
    local name = source:match("([^/]+)$")
    if name then
      table.insert(SYMLINKS, { source = source, dest = HOME .. "/.agents/skills/" .. name })
      table.insert(SYMLINKS, { source = source, dest = HOME .. "/.claude/skills/" .. name })
    end
  end
end

envy.extend(PACKAGES, { {
  spec = "local.symlink@r0",
  source = "envy/local.symlink@r0.lua",
  setup = { "links" },
  options = { links = SYMLINKS },
} })

envy.extend(PACKAGES, { {
  spec = "local.system_packages@r0",
  source = "envy/local.system_packages@r0.lua",
  setup = { "packages" },
  options = {
    manager = PACKAGE_MANAGER,
    packages = PACKAGE_PROFILE.packages,
    taps = PACKAGE_PROFILE.taps,
    casks = PACKAGE_PROFILE.casks,
  },
} })

envy.extend(PACKAGES, { {
  spec = "local.rustup@r0",
  source = "envy/local.rustup@r0.lua",
  setup = { "rustup" },
  options = {},
}, {
  spec = "local.rustup_toolchain@r0",
  source = "envy/local.rustup_toolchain@r0.lua",
  setup = { "toolchain" },
  options = { toolchain = "stable" },
} })

local CARGO_PACKAGES = {
  { repo = "https://github.com/hantianjz/tmx" },
  { repo = "https://github.com/hantianjz/rr_cli" },
}
envy.extend(CARGO_PACKAGES, PACKAGE_PROFILE.crates)

envy.extend(PACKAGES, { {
  spec = "local.cargo_install@r0",
  source = "envy/local.cargo_install@r0.lua",
  setup = { "crates" },
  options = { crates = CARGO_PACKAGES },
}, {
  spec = "local.uv_tool@r0",
  source = "envy/local.uv_tool@r0.lua",
  setup = { "tools" },
  options = { tools = { "bpython", "httpie" } },
} })

envy.extend(PACKAGES, {
  {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    setup = { "command" },
    options = {
      check = table.concat({
        "test -d " .. quote(TMUX_PLUGIN_DIR .. "/tmux-sensible"),
        "test -d " .. quote(TMUX_PLUGIN_DIR .. "/tmux-yank"),
        "test -d " .. quote(TMUX_PLUGIN_DIR .. "/tmux-resurrect"),
        "test -d " .. quote(TMUX_PLUGIN_DIR .. "/tmux-open-nvim"),
        "test -d " .. quote(TMUX_PLUGIN_DIR .. "/tmux-cpu"),
      }, " && "),
      install = quote(TMUX_PLUGIN_DIR .. "/tpm/scripts/install_plugins.sh"),
    },
  },
  {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    setup = { "command" },
    options = {
      check = "fish -c 'type -q fisher'",
      install =
      "fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'",
    },
  },
})

if PROFILE ~= "macos" then
  envy.extend(PACKAGES, { {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    setup = { "command" },
    options = {
      check = "command -v herdr >/dev/null 2>&1 || test -x " .. quote(HOME .. "/.local/bin/herdr"),
      install = "curl -fsSL https://herdr.dev/install.sh | sh",
    },
  } })
end
