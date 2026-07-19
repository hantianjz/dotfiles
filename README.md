# dotfiles

Declarative development environment setup using [Envy](https://github.com/charlesnicholson/envy).

## Supported platforms

- macOS on Intel or Apple Silicon, using Homebrew
- Ubuntu 24.04 LTS or newer, using APT
- Arch Linux on x86_64, using Pacman

Shared shell, Neovim, Git, Ghostty, tmux, scripts, and AI-skill links are managed on every platform. Aerospace is linked only on macOS. Hyprland input and binding overrides are linked only on Arch/Omarchy; Ubuntu does not receive either desktop-specific link set.

Ubuntu uses Cargo for portable CLI tools that are unavailable from the standard APT repositories. Ghostty and Lazygit are not automatically installed on Ubuntu.

## Fresh install

Clone the repository and run:

```sh
./setup
```

The setup script initializes submodules, bootstraps Homebrew when it is missing on macOS, downloads the pinned Envy release, and syncs the complete manifest. Extra arguments are forwarded to `envy sync`.

APT and Pacman are expected to be provided by their operating systems. Setup may ask for `sudo` when it installs system packages.

## Existing dotfiles

Envy never replaces a real file or directory at a symlink destination. It warns, preserves the existing destination, and continues with other links. Correct links are left alone, while stale or broken symlinks are replaced.

If an older setup accidentally created a link inside an existing destination directory, the warning identifies the possible nested link. Remove or relocate that content manually before running `./setup` again.

## Update

```sh
update
```

This updates the active native package manager, Rust and Cargo tools, uv tools, tmux plugins, and Fisher plugins. On Arch, it performs the required full-system Pacman upgrade.

## Maintenance

See [Cross-platform Envy maintainer guide](docs/envy-cross-platform.md) for the design strategy, package and symlink invariants, testing workflow, troubleshooting steps, and agent handoff checklist.
