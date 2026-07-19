# dotfiles

Declarative development environment setup for macOS and Linux using [envy](https://github.com/charlesnicholson/envy). Manages installation of CLI tools, shell configuration (fish), editor setup (neovim), terminal emulator (ghostty), window manager, tmux, and symlinks for all dotfiles.

## Fresh Install

```sh
./setup
```

This runs the pinned Envy bootstrap and syncs every package and setup task in
the manifest. Extra arguments are forwarded to `envy sync`.

On Linux, Envy installs system packages with Pacman when available and otherwise uses APT.

## Update

```sh
update
```

This updates Homebrew/APT packages, Rust toolchain, cargo crates, Python tools, tmux plugins, and fish plugins.
