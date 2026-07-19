-- envy.lua - Project manifest
-- @envy version "0.0.64"
-- @envy bin "bin"
-- @envy deploy "true"

local ROOT = debug.getinfo(1, "S").source:sub(2):match("(.*)/")
local HOME = os.getenv("HOME")
local TMUX_PLUGIN_DIR = HOME .. "/.config/tmux/plugins"

PACKAGES = {}

local function command_exists(command)
  local res = envy.run("command -v " .. command, {
    capture = true,
    quiet = true,
    check = false,
  })
  return res.exit_code == 0
end

local package_manager
if envy.PLATFORM == "darwin" then
  package_manager = "brew"
elseif envy.PLATFORM == "linux" then
  if command_exists("pacman") then
    package_manager = "pacman"
  elseif command_exists("apt-get") and command_exists("dpkg-query") then
    package_manager = "apt"
  else
    error("unsupported Linux package manager: expected pacman or apt-get with dpkg-query")
  end
end

-- Setup commands
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

-- Symlinks
local SYMLINKS = {
  -- Shell
  { source = ROOT .. "/fish",                       dest = HOME .. "/.config/fish" },
  { source = ROOT .. "/shellrc/bashrc",             dest = HOME .. "/.bashrc" },
  { source = ROOT .. "/shellrc/profile",            dest = HOME .. "/.profile" },
  -- Neovim
  { source = ROOT .. "/nvim",                       dest = HOME .. "/.config/nvim" },
  -- Git
  { source = ROOT .. "/config/gitconfig",           dest = HOME .. "/.gitconfig" },
  { source = ROOT .. "/config/gitignore",           dest = HOME .. "/.gitignore" },
  -- Ghostty
  { source = ROOT .. "/config/ghostty",             dest = HOME .. "/.config/ghostty" },
  -- Hyprland: keep Omarchy-specific files local; manage keyboard settings here.
  { source = ROOT .. "/config/hypr/input.conf",    dest = HOME .. "/.config/hypr/input.conf" },
  { source = ROOT .. "/config/hypr/bindings.conf", dest = HOME .. "/.config/hypr/bindings.conf" },
  -- Tmux
  { source = ROOT .. "/tmux",                       dest = HOME .. "/.config/tmux" },
  -- GDB
  { source = ROOT .. "/config/gdbinit",             dest = HOME .. "/.gdbinit" },
  -- Scripts
  { source = ROOT .. "/scripts/batch_find_replace", dest = HOME .. "/bin/batch_find_replace" },
  { source = ROOT .. "/scripts/find_replace",       dest = HOME .. "/bin/find_replace" },
  { source = ROOT .. "/scripts/grb",                dest = HOME .. "/bin/grb" },
  { source = ROOT .. "/scripts/gprune",             dest = HOME .. "/bin/gprune" },
  { source = ROOT .. "/scripts/usb",                dest = HOME .. "/bin/usb" },
}

-- Platform-specific symlinks
if envy.PLATFORM == "darwin" then
  table.insert(SYMLINKS, { source = ROOT .. "/config/aerospace.toml", dest = HOME .. "/.aerospace.toml" })
end

envy.extend(PACKAGES, { {
  spec = "local.symlink@r0",
  source = "envy/local.symlink@r0.lua",
  setup = { "links" },
  options = { links = SYMLINKS },
} })

-- AI skills symlinks
envy.extend(PACKAGES, { {
  spec = "local.ai_skills_symlink@r0",
  source = "envy/local.ai_skills_symlink@r0.lua",
  setup = { "links" },
  options = {
    source_dir = ROOT .. "/ai/skills",
    dest_roots = {
      HOME .. "/.agents/skills",
      HOME .. "/.claude/skills",
    },
  },
} })

-- Packages: strings for same name on both platforms, tables for platform-specific names
local PACKAGE_SPECS = {
  "bat", "binutils", "btop", "cmake", "direnv", "dos2unix", "fish", "fzf",
  { brew = "gh", apt = "gh", pacman = "github-cli" },
  "git-delta", "git-lfs", "gping", "hexyl", "hugo", "jq", "luarocks",
  "neovim", "nmap", "nnn", "pv", "ripgrep", "tmux", "wget", "zoxide",
  { brew = "fd",    apt = "fd-find",     pacman = "fd" },
  { brew = "ninja", apt = "ninja-build", pacman = "ninja" },
  { "diskus" },
  { "ghostty" },
  { "lazygit" },
  { "libusb" },
  { "typos-cli" },
  { "yazi" },
  { "eza" },
}

-- Platform-specific packages
if envy.PLATFORM == "darwin" then
  table.insert(PACKAGE_SPECS, { brew = "aerospace" })
elseif envy.PLATFORM == "linux" then
  envy.extend(PACKAGE_SPECS, {
    { apt = "libglib2.0-0",       pacman = "glib2" },
    { apt = "libglib2.0-dev" },
    { apt = "libudev-dev",        pacman = "systemd" },
    { apt = "libusb-1.0-0-dev",   pacman = "libusb" },
    { apt = "usbutils",           pacman = "usbutils" },
  })
end

-- Resolve package names for current platform
local INSTALL_PACKAGES = {}
for _, spec in ipairs(PACKAGE_SPECS) do
  if type(spec) == "string" then
    table.insert(INSTALL_PACKAGES, spec)
  elseif package_manager and spec[package_manager] then
    table.insert(INSTALL_PACKAGES, spec[package_manager])
  end
end

-- Install packages
if envy.PLATFORM == "darwin" then
  envy.extend(PACKAGES, { {
    spec = "local.brew_package@r0",
    source = "envy/local.brew_package@r0.lua",
    setup = { "packages" },
    options = {
      taps = { "qmk/qmk", "nikitabobko/tap" },
      packages = INSTALL_PACKAGES,
    },
  } })
elseif package_manager == "apt" then
  envy.extend(PACKAGES, { {
    spec = "local.apt@r0",
    source = "envy/local.apt@r0.lua",
    setup = { "packages" },
    options = { packages = INSTALL_PACKAGES },
  } })
elseif package_manager == "pacman" then
  envy.extend(PACKAGES, { {
    spec = "local.pacman@r0",
    source = "envy/local.pacman@r0.lua",
    setup = { "packages" },
    options = { packages = INSTALL_PACKAGES },
  } })
end

-- Rustup
envy.extend(PACKAGES, { {
  spec = "local.rustup@r0",
  source = "envy/local.rustup@r0.lua",
  setup = { "rustup" },
  options = {},
} })

-- Rust toolchain
envy.extend(PACKAGES, { {
  spec = "local.rustup_toolchain@r0",
  source = "envy/local.rustup_toolchain@r0.lua",
  setup = { "toolchain" },
  options = { toolchain = "stable" },
} })

-- Rust crates (cargo install --git)
envy.extend(PACKAGES, { {
  spec = "local.cargo_install@r0",
  source = "envy/local.cargo_install@r0.lua",
  setup = { "crates" },
  options = {
    crates = {
      { repo = "https://github.com/hantianjz/tmx" },
      { repo = "https://github.com/hantianjz/rr_cli" },
    },
  },
} })

-- Python tools (uv tool install)
envy.extend(PACKAGES, { {
  spec = "local.uv_tool@r0",
  source = "envy/local.uv_tool@r0.lua",
  setup = { "tools" },
  options = {
    tools = { "bpython", "httpie" },
  },
} })

-- Post-install commands
envy.extend(PACKAGES, {
  {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    setup = { "command" },
    options = {
      check = table.concat({
        "test -d " .. TMUX_PLUGIN_DIR .. "/tmux-sensible",
        "test -d " .. TMUX_PLUGIN_DIR .. "/tmux-yank",
        "test -d " .. TMUX_PLUGIN_DIR .. "/tmux-resurrect",
        "test -d " .. TMUX_PLUGIN_DIR .. "/tmux-open-nvim",
        "test -d " .. TMUX_PLUGIN_DIR .. "/tmux-cpu",
      }, " && "),
      install = TMUX_PLUGIN_DIR .. "/tpm/scripts/install_plugins.sh",
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
