# dotfiles

Declarative development environment setup using [Envy](https://github.com/envy-package-manager/envy).

## Supported platforms

- macOS on Intel or Apple Silicon, using Homebrew
- Ubuntu 24.04 LTS or newer, using APT
- Arch Linux on x86_64, using Pacman

Shared shell, Neovim, Git, Ghostty, tmux, Herdr, scripts, and AI-skill links are managed on every platform. Herdr independently uses the same `Ctrl-a`-prefixed pane and tab bindings as tmux where practical; `Ctrl-a Ctrl-a` sends a literal `Ctrl-a` to the active program. Aerospace is linked only on macOS. Personal Hyprland overrides target Omarchy v4.0.4 and are linked individually only on Arch; Ubuntu does not receive either desktop-specific link set. Existing Omarchy installations must follow the [bounded migration procedure](docs/envy-cross-platform.md#omarchy-v404-cutover) before deploying the Lua configuration.

Ubuntu uses Cargo for portable CLI tools that are unavailable from the standard APT repositories. Ghostty and Lazygit are not automatically installed on Ubuntu.

## Fresh install

Clone the repository and run:

```sh
./setup
```

The setup script initializes submodules, bootstraps Homebrew when it is missing on macOS, downloads the pinned Envy release, and syncs the complete manifest. Extra arguments are forwarded to `envy sync`.

APT and Pacman are expected to be provided by their operating systems. Setup may ask for `sudo` when it installs system packages.

### Omarchy 4.0+

Run setup as your desktop user **inside the upgraded Hyprland session**, not with `sudo`. Plain `./setup` backs up and adopts the personal Hyprland configuration before running the normal package/tool setup.

For configuration only, without package installation or submodule updates:

```sh
./setup --omarchy-config
```

The cutover preserves original files and symlink targets under `~/omarchy-config-backup.*`, installs the eight managed files, reloads Hyprland, and checks configuration errors. Installation or parser failure restores displaced destinations; unrelated files are untouched. Missing content behind an already dangling link is reported, not claimed as backed up. Password/fingerprint setup is not changed.

Omarchy 3 and unknown/development version strings are rejected. Complete the supported upgrade separately; back up and detach repository-owned links **before upgrading Omarchy or updating this checkout**. The setup-time backup cannot recover bytes already changed or removed by either update. See the [cutover and live checks](docs/envy-cross-platform.md#omarchy-v404-cutover).

Explicit Envy arguments, such as `./setup --strict`, are forwarded without the automatic cutover. Run `./setup --omarchy-config` separately when adopting generated Omarchy files. `--omarchy-config` takes no additional arguments.

## Existing dotfiles

Envy preserves differing real files and directories at symlink destinations: it warns and continues with other links. A regular file identical to its source can be adopted as a managed symlink. Correct links are left alone, while stale or broken symlinks are replaced.

If an older setup accidentally created a link inside an existing destination directory, the warning identifies the possible nested link. Remove or relocate that content manually before running `./setup` again.

## Update

```sh
update
```

This updates the active native package manager, Rust and Cargo tools, uv tools, tmux plugins, and Fisher plugins. On Arch, it performs the required full-system Pacman upgrade.

## Maintenance

See [Cross-platform Envy maintainer guide](docs/envy-cross-platform.md) for the design strategy, package and symlink invariants, testing workflow, troubleshooting steps, and agent handoff checklist.

For the ThinkPad T480s fingerprint reader, see the [Omarchy fingerprint setup runbook](docs/omarchy-t480s-fingerprint.md). It records the legacy Synaptics driver replacement, enrollment workflow, power-management fix, troubleshooting, and rollback steps.
