local M = {}

local common_packages = {
  "bat", "binutils", "btop", "cmake", "direnv", "dos2unix", "fish", "fzf",
  "git-lfs", "hugo", "jq", "luarocks", "neovim", "nmap", "nnn", "pv",
  "ripgrep", "tmux", "wget", "zoxide",
}

local package_aliases = {
  { brew = "gh",          apt = "gh",          pacman = "github-cli" },
  { brew = "fd",          apt = "fd-find",     pacman = "fd" },
  { brew = "ninja",       apt = "ninja-build", pacman = "ninja" },
  { brew = "libusb",      apt = "libusb-1.0-0-dev", pacman = "libusb" },
}

local portable_ubuntu_crates = {
  { package = "diskus" },
  { package = "eza" },
  { package = "git-delta", binary = "delta" },
  { package = "gping" },
  { package = "hexyl" },
  { package = "typos-cli", binary = "typos" },
  { package = "yazi-build", force = true },
}

local function append(target, values)
  for _, value in ipairs(values) do
    table.insert(target, value)
  end
end

function M.detect(platform, command_exists)
  if platform == "darwin" then
    return "macos", "brew"
  end

  if platform ~= "linux" then
    error("unsupported platform: " .. tostring(platform))
  end

  if command_exists("pacman") then
    return "arch", "pacman"
  end
  if command_exists("apt-get") and command_exists("dpkg-query") then
    return "ubuntu", "apt"
  end

  error("unsupported Linux package manager: expected pacman or apt-get with dpkg-query")
end

function M.packages(profile, manager)
  local packages = {}
  append(packages, common_packages)
  for _, aliases in ipairs(package_aliases) do
    local package = assert(aliases[manager], "missing package alias for " .. manager)
    table.insert(packages, package)
  end

  local casks = {}
  local crates = {}

  if profile == "macos" then
    append(packages, {
      "diskus", "eza", "git-delta", "gping", "hexyl", "lazygit",
      "herdr", "tuicr", "typos-cli", "yazi",
    })
    append(casks, { "ghostty", "aerospace" })
  elseif profile == "arch" then
    append(packages, {
      "diskus", "eza", "git-delta", "ghostty", "gping", "hexyl", "lazygit",
      "systemd", "typos", "usbutils", "wl-clipboard", "yazi",
    })
  elseif profile == "ubuntu" then
    append(packages, { "libglib2.0-dev", "libudev-dev", "usbutils", "wl-clipboard" })
    append(crates, portable_ubuntu_crates)
  else
    error("unknown platform profile: " .. tostring(profile))
  end

  return {
    packages = packages,
    casks = casks,
    taps = profile == "macos" and { "agavra/tap", "nikitabobko/tap" } or {},
    crates = crates,
  }
end

function M.desktop_links(profile, root, home)
  if profile == "arch" then
    local links = {}
    local hypr_files = {
      "autostart.lua",
      "bindings.lua",
      "hyprland.lua",
      "hyprsunset.conf",
      "input.lua",
      "looknfeel.lua",
      "monitors.lua",
      "xdph.conf",
    }
    for _, filename in ipairs(hypr_files) do
      table.insert(links, {
        source = root .. "/config/hypr/" .. filename,
        dest = home .. "/.config/hypr/" .. filename,
      })
    end
    return links
  end
  if profile == "macos" then
    return { {
      source = root .. "/config/aerospace.toml",
      dest = home .. "/.aerospace.toml",
    } }
  end
  if profile == "ubuntu" then
    return {}
  end
  error("unknown platform profile: " .. tostring(profile))
end

return M
