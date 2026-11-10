-- envy.lua - Project manifest
-- @envy version "0.5.1"
-- @envy sha256sums "3ab2574d9e651564c53cd257911c43d10b99cfed297ceda273059946117ec911"
-- @envy bin "bin"
-- @envy deploy "true"

local MANIFEST = debug.getinfo(1, "S").source:sub(2)
local ROOT = MANIFEST:match("(.*)/") or "."
if ROOT:sub(1, 1) ~= "/" then
  local cwd = assert(os.getenv("PWD"), "PWD is not set")
  ROOT = ROOT == "." and cwd or cwd .. "/" .. ROOT
end
local HOME = assert(os.getenv("HOME"), "HOME is not set")
local platform = dofile(ROOT .. "/envy/platform.lua")

local tmux = envy.import("envy/tmux.lua")
PACKAGES = {}
envy.extend(PACKAGES, tmux.PACKAGES)

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

local MACHINE_PROFILE_EMAILS = {
  personal = "hjz@hackjumpzero.ca",
  work = "hjz@block.xyz",
}
local MACHINE_PROFILE_PATH = HOME .. "/.dotfiles_profile"

local function read_machine_profile(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local line = file:read("*l")
  file:close()
  if line == "" then
    return nil
  end
  return line
end

local MACHINE_PROFILE = os.getenv("DOTFILES_PROFILE")
if not MACHINE_PROFILE or MACHINE_PROFILE == "" then
  MACHINE_PROFILE = read_machine_profile(MACHINE_PROFILE_PATH)
end
local MACHINE_PROFILE_EMAIL = MACHINE_PROFILE and MACHINE_PROFILE_EMAILS[MACHINE_PROFILE] or nil
if MACHINE_PROFILE and not MACHINE_PROFILE_EMAIL then
  error("unknown dotfiles profile '" .. MACHINE_PROFILE .. "' (expected personal or work)")
end

if MACHINE_PROFILE_EMAIL then
  envy.extend(PACKAGES, { {
    spec = "local.profile@r0",
    source = "envy/local.profile@r0.lua",
    setup = { "profile" },
    options = {
      profile = MACHINE_PROFILE,
      profile_path = MACHINE_PROFILE_PATH,
      gitconfig_path = HOME .. "/.gitconfig_local",
      git_user_email = MACHINE_PROFILE_EMAIL,
    },
  } })
end

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
  { source = ROOT .. "/ai/CLAUDE.md",              dest = HOME .. "/.claude/CLAUDE.md" },
  { source = ROOT .. "/ai/CLAUDE.md",              dest = HOME .. "/.codex/AGENTS.md" },
  { source = ROOT .. "/ai/CLAUDE.md",              dest = HOME .. "/.agents/AGENTS.md" },
  { source = ROOT .. "/ai/CLAUDE.md",              dest = HOME .. "/.omp/agent/AGENTS.md" },
  { source = ROOT .. "/fish",                      dest = HOME .. "/.config/fish" },
  { source = ROOT .. "/shellrc/environment",       dest = HOME .. "/.config/shell/environment" },
  { source = ROOT .. "/shellrc/bashrc",            dest = HOME .. "/.bashrc" },
  { source = ROOT .. "/shellrc/profile",           dest = HOME .. "/.profile" },
  { source = ROOT .. "/nvim",                      dest = HOME .. "/.config/nvim" },
  { source = ROOT .. "/config/gitconfig",          dest = HOME .. "/.gitconfig" },
  { source = ROOT .. "/config/gitignore",          dest = HOME .. "/.gitignore" },
  { source = ROOT .. "/config/ghostty",            dest = HOME .. "/.config/ghostty" },
  { source = ROOT .. "/config/herdr/config.toml",  dest = HOME .. "/.config/herdr/config.toml" },
  { source = ROOT .. "/scripts/herdr-tmux-action", dest = HOME .. "/.config/herdr/herdr-tmux-action" },
  {
    source = ROOT .. "/config/herdr-automatic-rename/config.sh",
    dest = HOME .. "/.config/herdr-automatic-rename/config.sh"
  },
  { source = ROOT .. "/tmux",                       dest = HOME .. "/.config/tmux" },
  { source = ROOT .. "/config/gdbinit",             dest = HOME .. "/.gdbinit" },
  { source = ROOT .. "/scripts/batch_find_replace", dest = HOME .. "/bin/batch_find_replace" },
  { source = ROOT .. "/scripts/find_replace",       dest = HOME .. "/bin/find_replace" },
  { source = ROOT .. "/scripts/grb",                dest = HOME .. "/bin/grb" },
  { source = ROOT .. "/scripts/gprune",             dest = HOME .. "/bin/gprune" },
  { source = ROOT .. "/scripts/usb",                dest = HOME .. "/bin/usb" },
}

envy.extend(SYMLINKS, platform.desktop_links(PROFILE, ROOT, HOME))
for _, package in ipairs(tmux.PACKAGES) do
  local name = package.options.dest
  table.insert(SYMLINKS, {
    source = ROOT .. "/" .. package.vendor .. "/" .. name,
    dest = ROOT .. "/tmux/plugins/" .. name,
  })
end

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
  spec = "local.omp@r0",
  source = "envy/local.omp@r0.lua",
  setup = { "tools" },
  options = {},
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

local CARGO_PACKAGES = {}
envy.extend(CARGO_PACKAGES, PACKAGE_PROFILE.crates)

envy.extend(PACKAGES, { {
  spec = "local.cargo_github_tmx@r0",
  source = "envy/local.cargo_github_tmx@r0.lua",
  setup = { "tool" },
}, {
  spec = "local.cargo_install@r0",
  source = "envy/local.cargo_install@r0.lua",
  setup = { "crates" },
  options = { crates = CARGO_PACKAGES, build_helper = ROOT .. "/scripts/with-build-temp" },
} })

envy.extend(PACKAGES, {
  {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    setup = { "command" },
    options = {
      check = [[fish -c '
        type -q fisher; or exit 1
        set -l plugins (string match --regex -- "^[^\s]+\$" < $__fish_config_dir/fish_plugins); or exit 1
        set -l installed (fisher list)
        for plugin in $plugins
          contains -- $plugin $installed; or exit 1
        end
      ']],
      install = [[fish -c '
        set -l plugins (string match --regex -- "^[^\s]+\$" < $__fish_config_dir/fish_plugins); or exit 1
        if not type -q fisher
          set -l fisher_source (curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish); or exit 1
          printf "%s\n" $fisher_source | source; or exit 1
        end
        fisher install $plugins; or exit 1
        set -l installed (fisher list)
        for plugin in $plugins
          contains -- $plugin $installed; or exit 1
        end
      ']],
    },
  },
})


local HERDR_APP_SUPPORTED = PROFILE ~= "macos" or envy.run(
  'test "$(uname -m)" = arm64 || test "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1',
  { capture = true, quiet = true, check = false }
).exit_code == 0
if HERDR_APP_SUPPORTED then
  envy.extend(PACKAGES, { {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    setup = { "command" },
    options = {
      check = "command -v herdr-app >/dev/null 2>&1 || test -x " .. quote(HOME .. "/.local/bin/herdr-app"),
      install = "set -o pipefail\ncurl -fsSL https://releases.herdr.dev/app/install.sh | sh",
    },
  } })
end

local HERDR_PLUGINS = {}
for plugin in io.lines(ROOT .. "/config/herdr/plugins") do
  if plugin ~= "" and plugin:sub(1, 1) ~= "#" then
    table.insert(HERDR_PLUGINS, plugin)
  end
end
envy.extend(PACKAGES, { {
  spec = "local.herdr@r0",
  source = "envy/local.herdr@r0.lua",
  setup = { "plugins" },
  options = { plugins = HERDR_PLUGINS },
} })
