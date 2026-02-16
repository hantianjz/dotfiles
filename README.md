# dotfiles

Declarative development environment setup for macOS and Linux using [envy](https://github.com/charlesnicholson/envy). Manages installation of CLI tools, shell configuration (fish), editor setup (neovim), terminal emulator (ghostty), window manager, tmux, and symlinks for all dotfiles.

## Fresh Install

```sh
cd envy && bin/envy
```

## Update

```sh
cd envy && bin/update
```

This updates Homebrew/APT packages, Rust toolchain, cargo crates, Python tools, tmux plugins, and fish plugins.
