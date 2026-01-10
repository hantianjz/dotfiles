-- envy.lua - Project manifest
-- @envy version "0.0.0"

PACKAGES = {
}

if envy.PLATFORM == "darwin" then
  envy.extend(PACKAGES, { {
    recipe = "local.brew_package@r0",
    source = "local.brew_package@r0.lua",
    options = { taps = { "qmk/qmk", "nikitabobko/tap" }, packages = { "ghostty", "neovim", "pv", "bat", "libusb", "btop", "fd", "ripgrep", "direnv", "gh", "git-delta", "git-lfs", "hexyl", "tmux", "typos-cli", "zoxide", "aerospace", "wget", "nnn", } }
  } })
end

if envy.PLATFORM == "linux" then
  envy.extend(PACKAGES, { {
    recipe = "local.apt@r0",
    source = "local.apt@r0.lua",
    options = {
      packages = {
        "libglib2.0-0", "libglib2.0-dev", "libudev-dev", "libusb-1.0-0-dev" }
    }
  } })
end
