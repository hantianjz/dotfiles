-- envy.lua - Project manifest
-- @envy version "0.0.23"
-- @envy bin "bin"
-- @envy deploy "true"

local ROOT = debug.getinfo(1, "S").source:sub(2):match("(.*)/")
local HOME = os.getenv("HOME")

PACKAGES = {}

-- Setup commands
envy.extend(PACKAGES, { {
  spec = "local.file_setup@r0",
  source = "envy/local.file_setup@r0.lua",
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
  source = "envy/local.symlink@r0.lua",
  options = { links = SYMLINKS },
} })

-- AI skills symlinks
envy.extend(PACKAGES, { {
  spec = "local.ai_skills_symlink@r0",
  source = "envy/local.ai_skills_symlink@r0.lua",
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
    source = "envy/local.brew_package@r0.lua",
    options = {
      taps = { "qmk/qmk", "nikitabobko/tap" },
      packages = INSTALL_PACKAGES,
    },
  } })
elseif envy.PLATFORM == "linux" then
  envy.extend(PACKAGES, { {
    spec = "local.apt@r0",
    source = "envy/local.apt@r0.lua",
    options = { packages = INSTALL_PACKAGES },
  } })
end

-- Rustup
envy.extend(PACKAGES, { {
  spec = "local.rustup@r0",
  source = "envy/local.rustup@r0.lua",
  options = {},
} })

-- Rust toolchain
envy.extend(PACKAGES, { {
  spec = "local.rustup_toolchain@r0",
  source = "envy/local.rustup_toolchain@r0.lua",
  options = { toolchain = "stable" },
} })

-- Rust crates (cargo install --git)
envy.extend(PACKAGES, { {
  spec = "local.cargo_install@r0",
  source = "envy/local.cargo_install@r0.lua",
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
  options = {
    tools = { "bpython", "httpie" },
  },
} })

-- Post-install commands
envy.extend(PACKAGES, {
  {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    options = {
      check = "test -f " .. HOME .. "/.tmux/plugins/tpm/tpm",
      install = HOME .. "/.tmux/plugins/tpm/scripts/install_plugins.sh",
    },
  },
  {
    spec = "local.shell@r0",
    source = "envy/local.shell@r0.lua",
    options = {
      check = "fish -c 'type -q fisher'",
      install =
      "fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'",
    },
  },
})
