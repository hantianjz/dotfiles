# dotfiles

Declarative development environment setup using [Envy](https://github.com/envy-package-manager/envy).

## Supported platforms

- macOS on Intel or Apple Silicon, using Homebrew
- Ubuntu 24.04 LTS or newer, using APT
- Arch Linux on x86_64, using Pacman

Shared shell, Neovim, Git, Ghostty, tmux, scripts, and AI-skill links are managed on every platform. Aerospace is linked only on macOS. Personal Hyprland overrides target Omarchy v4.0.4 and are linked individually only on Arch; Ubuntu does not receive either desktop-specific link set. Existing Omarchy installations must follow the [bounded migration procedure](docs/envy-cross-platform.md#omarchy-v404-cutover) before deploying the Lua configuration.

Ubuntu installs portable Rust CLIs from upstream prebuilt releases with `cargo-binstall`, and Yazi from its official `.deb`. No Rust CLI source-build fallback runs during setup or updates.

Ghostty installs through Homebrew on macOS, Pacman on Arch, and the official APT repositories on Ubuntu 26.04 or newer. Ubuntu 24.04 keeps its Ghostty configuration link but does not install Ghostty automatically. Lazygit is not automatically installed on Ubuntu.

Ubuntu retains `build-essential` and Rustup's stable toolchain as development tools. Shell plugin setup waits for native packages.

Ubuntu installs the latest stable Neovim from [official upstream releases](https://github.com/neovim/neovim/releases/latest), not APT. Setup and `update` verify the release archive's SHA-256 and expose it as `~/.local/bin/nvim`; existing APT installations remain untouched.

Rustup leaves shell startup files unchanged; the shared shell environment owns Cargo's `PATH` entry.

Fisher owns its generated manager files and installs every plugin in `fish/fish_plugins`. Setup checks the complete installed list.

## Fresh install

Clone the repository and run:

```sh
./setup
```

The setup script asks for a machine profile on the first full sync, stores it in `~/.dotfiles_profile`, bootstraps Homebrew when it is missing on macOS, downloads the pinned Envy release, and syncs the complete manifest. Extra arguments are forwarded to `envy sync`.
For non-interactive setup, pass the profile explicitly:

```sh
./setup --profile work
./setup --profile personal
```

The `work` profile writes `user.email = hjz@block.xyz` to `~/.gitconfig_local`; the `personal` profile writes `user.email = hjz@hackjumpzero.ca`. Other settings in `~/.gitconfig_local` are preserved.

GitHub credentials use `gh` from `PATH`, on both macOS and Linux. Authenticate separately on each machine.

APT and Pacman are expected to be provided by their operating systems. Setup may ask for `sudo` when it installs system packages.

Setup also installs [Bun](https://bun.sh) and [Oh My Pi](https://omp.sh), then enables `github:phenome/omp-ponytail-caveman`. Existing executables are reused. On macOS, fresh omp installs use `brew install can1357/tap/omp`; Linux uses the upstream installer in `~/.local/bin`. Bun installs in `~/.bun/bin`. Both user directories are available in Fish and POSIX/Bash shells.

Neovim runs Bash, JSON, TypeScript/JavaScript, and Pyright language servers with Bun, without Node.js or npm. Setup installs their packages globally in `~/.bun`; Mason manages the other servers. Rerun `./setup` on an existing installation, then restart Neovim. Keep TypeScript below version 7 for `typescript-language-server`.

Setup installs the [Herdr desktop app](https://herdr.dev/download/) separately from Herdr TUI, using the official installer on Apple Silicon macOS and Linux. Intel Macs skip the desktop app because upstream provides no Intel build. The installer places `Herdr.app` in `~/Applications` on macOS or installs into `${XDG_DATA_HOME:-~/.local/share}/herdr-app` with a desktop launcher on Linux. Both platforms get `~/.local/bin/herdr-app`. The installer also installs herdr-core when missing; the app keeps herdr-core current. Existing `herdr-app` executables are reused.

Setup does not install Herdr TUI or manage its configuration and plugins. Existing TUI installations are left untouched.

Setup links `config/herdr-app/keys.json` and `settings.json` into `${HERDR_APP_HOME:-~/.config/herdr-app}`. Edit these repository files to change app shortcuts and preferences; changes reload automatically. The bindings reserve `Cmd-h/j/k/l` for app panes and leave `Ctrl-h/j/k/l` for Neovim. App-managed mods, layouts, themes, sessions, and window state remain local. Identical existing files become links; differing files are preserved with a warning. Merge wanted settings into the repository, back up and move conflicting files aside, then rerun setup.

The desktop app uses Catppuccin Mocha colors in `settings.json`, matching Neovim. Terminal ANSI colors and app panels share this palette.

Use repository edits for managed preferences, not the app Settings UI: its atomic file writes can replace a configuration symlink. If that happens, merge the local changes into the repository, back up and move the regular file aside, then run `./bin/envy install local.herdr_app@r0` to restore the link.

Setup links `ai/work/AGENTS.md` for the `work` profile and `ai/CLAUDE.md` for the `personal` profile as the shared instruction file for Claude Code, Codex, agents-compatible tools, and omp:

- `~/.claude/CLAUDE.md`
- `~/.codex/AGENTS.md`
- `~/.agents/AGENTS.md`
- `~/.omp/agent/AGENTS.md`

The same links are managed by direct `./bin/envy sync` runs using `DOTFILES_PROFILE` or the saved `~/.dotfiles_profile`; without either, they use the personal file. Switching profiles repoints existing symlinks. Differing existing regular files are preserved with a warning; merge wanted instructions into the selected profile's file, back up and move conflicting files aside, then rerun setup. This includes tool-managed additions such as `sq agents` blocks. Start a new agent session after setup to load the shared instructions. Omp uses its native global file without enabling Claude or Codex discovery.

### Omarchy 4.0+

Run setup as your desktop user **inside the upgraded Hyprland session**, not with `sudo`. Plain `./setup` backs up and adopts the personal Hyprland configuration before running the normal package/tool setup.

For configuration only, without package installation or dependency downloads:

```sh
./setup --omarchy-config
```

The cutover preserves original files and symlink targets under `~/omarchy-config-backup.*`, installs the eight managed files, reloads Hyprland, and checks configuration errors. Installation or parser failure restores displaced destinations; unrelated files are untouched. Missing content behind an already dangling link is reported, not claimed as backed up. Password/fingerprint setup is not changed.

Omarchy 3 and unknown/development version strings are rejected. Complete the supported upgrade separately; back up and detach repository-owned links **before upgrading Omarchy or updating this checkout**. The setup-time backup cannot recover bytes already changed or removed by either update. See the [cutover and live checks](docs/envy-cross-platform.md#omarchy-v404-cutover).

Explicit Envy arguments, such as `./setup --strict`, are forwarded without the automatic cutover. Run `./setup --omarchy-config` separately when adopting generated Omarchy files. `--omarchy-config` takes no additional arguments.

## Existing dotfiles

Envy preserves differing real files and directories at symlink destinations: it warns and continues with other links. A regular file identical to its source can be adopted as a managed symlink. Correct links are left alone, while stale or broken symlinks are replaced.

Setup links `config/rex/init.lua` to `~/.config/rex/init.lua`. Edit the repository file, then run `rex config reload`. Rex keeps default font controls, copy-mode keys, and the command palette (`Cmd+Shift+P`). It uses `Ctrl+a` sequences for pane and tab management. `Cmd+Shift+W` closes the tab.

Press `Ctrl+a` then `[` to enter copy mode. Press `v` to start selection and `y` to copy and exit.

Rex uses `Ctrl+h/j/k/l` to focus panes, so these keys do not reach Neovim. macOS shortcuts and shortcuts set through Rex's Change Shortcut command are separate. Rex installation is separate.

If an older setup accidentally created a link inside an existing destination directory, the warning identifies the possible nested link. Remove or relocate that content manually before running `./setup` again.

All eight tmux repositories are commit-pinned in `envy/tmux.lua`, using the first-party GitHub helper with Envy 0.5.1. Envy vendors them into `.envy/tmux/<name>/<name>`; managed links expose them at `tmux/plugins/<name>`. TPM only loads installed plugins; Envy owns acquisition and updates.

For an existing checkout, inspect and move old real directories at `tmux/plugins/<name>` outside the checkout before the first migrated setup. Preserve any local changes. Envy warns and preserves conflicting directories instead of replacing them. The same policy preserves a user-owned `~/.config/tmux`; back up and move it aside only when adopting this repository's configuration.

## Omp settings backup

With [uv](https://docs.astral.sh/uv/getting-started/installation/) on `PATH`, the script invokes uv directly and needs no Python packages:

```sh
./bin/omp-backup inventory
./bin/omp-backup backup "$HOME/omp-settings.tar.gz"
# On the target machine, after installing uv and running ./setup:
./bin/omp-backup restore "$HOME/omp-settings.tar.gz" --dry-run
./bin/omp-backup restore "$HOME/omp-settings.tar.gz"
```

The private archive includes omp settings, plugin manifests, and Plannotator configuration. Skills and skill-manager metadata are excluded; reinstall skills through their existing installers and preserve their source separately. `./setup` only links personal skills already present in `ai/skills/`, which is currently empty. Restore preserves dotfiles-managed links and refuses differing existing files unless `--replace` is supplied; replacement saves originals. Credentials, conversations, caches, and installed dependencies are excluded. Rebuild plugin dependencies for the target OS and authenticate separately.

See [the configuration inventory and migration guide](docs/omp-settings.md) for exact coverage, recovery, Linux prerequisites, and the manual checklist for browser-only Plannotator preferences.

## Update

```sh
update
```

This updates the active native package manager, Bun, omp, the configured omp Git plugin, Rust, prebuilt CLI tools, tmux plugins, and Fisher plugins. It does not update uv tools. The omp Git plugin is refreshed with `omp plugin install github:phenome/omp-ponytail-caveman`; `omp update --plugins` only upgrades marketplace plugins. On Omarchy, it delegates the required full-system Pacman upgrade to `omarchy update -y`, which preserves Omarchy's snapshot, migration, hook, and restart flow.

The updater continues after individual command failures, reports their count, and exits 1. A successful run exits 0; unavailable optional tools are skipped.

Tmux's theme stays pinned to v2.3.2, and all eight plugin revisions live in `envy/tmux.lua`. The updater runs `envy vendor --all` for repository-managed tmux configuration, restoring the declared revisions without Git pulls or submodule updates. To upgrade a plugin, resolve and review a new commit with `./bin/envy git-resolve`, update its pin, then run setup. Edits inside `.envy/tmux` are disposable and are replaced during synchronization.

Native-manager selection follows `envy/platform.lua`: Homebrew on macOS; on Linux, Pacman first, otherwise APT only when both `apt-get` and `dpkg-query` are available. Arch systems without Omarchy use Pacman directly. If no supported manager is available, native updates are skipped. Yazi's `.deb` and `cargo-binstall` run only when APT is selected. Scoped Envy installs retain the declared Yazi release pin; Ubuntu's six other Rust CLIs follow upstream releases.

On macOS, Homebrew upgrades omp; the updater does not run `omp update`. Other profiles retain `omp update`. The configured Git plugin refreshes on all profiles.

Ghostty follows native package updates through Homebrew on macOS, APT on Ubuntu 26.04 or newer, and Pacman/Omarchy on Arch.

The updater refreshes an installed Herdr desktop app by rerunning its official installer, including on Omarchy, then repairs its configuration links with `envy install local.herdr_app@r0`. Missing desktop app installations are skipped. To apply only the configuration without updating software, run `./bin/envy install local.herdr_app@r0`. Herdr TUI installation, updates, configuration, and plugins remain separate.

## Maintenance

See [Cross-platform Envy maintainer guide](docs/envy-cross-platform.md) for the design strategy, package and symlink invariants, testing workflow, troubleshooting steps, and agent handoff checklist.

For the ThinkPad T480s fingerprint reader, see the [Omarchy fingerprint setup runbook](docs/omarchy-t480s-fingerprint.md). It records the legacy Synaptics driver replacement, enrollment workflow, power-management fix, troubleshooting, and rollback steps.
