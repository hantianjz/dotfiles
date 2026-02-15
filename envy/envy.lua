-- envy.lua - Project manifest
-- @envy version "0.0.22"
-- @envy bin "bin"
-- @envy deploy "true"

local ROOT = "/Users/hjz/.dotfiles"
local HOME = os.getenv("HOME")

PACKAGES = {}

-- Setup commands
envy.extend(PACKAGES, {
  {
    spec = "local.shell@r0",
    source = "local.shell@r0.lua",
    options = {
      check = "test -d " .. HOME .. "/bin",
      install = "mkdir -p " .. HOME .. "/bin",
    },
  },
  {
    spec = "local.shell@r0",
    source = "local.shell@r0.lua",
    options = {
      check = "test -d " .. HOME .. "/.vim/backup",
      install = "mkdir -p " .. HOME .. "/.vim/backup",
    },
  },
  {
    spec = "local.shell@r0",
    source = "local.shell@r0.lua",
    options = {
      check = "test -f " .. HOME .. "/.gitconfig_local",
      install = "touch " .. HOME .. "/.gitconfig_local",
    },
  },
})

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
  -- Tmux
  { source = ROOT .. "/config/tmux.conf",           dest = HOME .. "/.tmux.conf" },
  { source = ROOT .. "/tmux",                       dest = HOME .. "/.tmux" },
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
  source = "local.symlink@r0.lua",
  options = { links = SYMLINKS },
} })

-- Packages: strings for same name on both platforms, tables for platform-specific names
local PACKAGE_SPECS = {
  "bat", "binutils", "btop", "cmake", "direnv", "dos2unix", "fish", "fzf",
  "gh", "git-delta", "git-lfs", "gping", "hexyl", "hugo", "jq", "luarocks",
  "neovim", "nmap", "nnn", "pv", "ripgrep", "tmux", "wget", "zoxide",
  { brew = "fd",    apt = "fd-find" },
  { brew = "ninja", apt = "ninja-build" },
  { "diskus" },
  { "ghostty" },
  { "lazygit" },
  { "libusb" },
  { "typos-cli" },
  { "yazi" },
  { "uv" },
}

-- Platform-specific packages
if envy.PLATFORM == "darwin" then
  table.insert(PACKAGE_SPECS, { brew = "aerospace" })
elseif envy.PLATFORM == "linux" then
  for _, pkg in ipairs({
    "libglib2.0-0", "libglib2.0-dev", "libudev-dev", "libusb-1.0-0-dev",
    "usbutils",
  }) do
    table.insert(PACKAGE_SPECS, { apt = pkg })
  end
end

-- Resolve package names for current platform
local INSTALL_PACKAGES = {}
local platform_key = envy.PLATFORM == "darwin" and "brew" or "apt"
for _, spec in ipairs(PACKAGE_SPECS) do
  if type(spec) == "string" then
    table.insert(INSTALL_PACKAGES, spec)
  elseif spec[platform_key] then
    table.insert(INSTALL_PACKAGES, spec[platform_key])
  end
end

-- Install packages
if envy.PLATFORM == "darwin" then
  envy.extend(PACKAGES, { {
    spec = "local.brew_package@r0",
    source = "local.brew_package@r0.lua",
    options = {
      taps = { "qmk/qmk", "nikitabobko/tap" },
      packages = INSTALL_PACKAGES,
    },
  } })
elseif envy.PLATFORM == "linux" then
  envy.extend(PACKAGES, { {
    spec = "local.apt@r0",
    source = "local.apt@r0.lua",
    options = { packages = INSTALL_PACKAGES },
  } })
end

-- Post-install commands
envy.extend(PACKAGES, {
  {
    spec = "local.shell@r0",
    source = "local.shell@r0.lua",
    options = {
      check = "test -f " .. HOME .. "/.tmux/plugins/tpm/tpm",
      install = HOME .. "/.tmux/plugins/tpm/scripts/install_plugins.sh",
    },
  },
  {
    spec = "local.shell@r0",
    source = "local.shell@r0.lua",
    options = {
      check = "fish -c 'type -q fisher'",
      install =
      "fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'",
    },
  },
})
