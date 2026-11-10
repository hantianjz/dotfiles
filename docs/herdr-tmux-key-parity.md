# Herdr–tmux key parity

`config/herdr/config.toml` mirrors the personal prefix bindings in
`tmux/tmux.keys.conf` when Herdr has an exact or deterministic equivalent.
It also includes tmux-sensible's `Ctrl-a Ctrl-p` / `Ctrl-a Ctrl-n` window
navigation.

Herdr keeps `Ctrl-a b` for its sidebar. This intentionally differs from
tmux-sensible's last-window binding. Herdr and tmux are configured as
independent multiplexers and are not intended to be nested. Herdr's built-in
double-prefix behavior sends a literal `Ctrl-a` to the active program.

Direct `Ctrl-h/j/k/l` is process-aware in both multiplexers. tmux uses
`vim-tmux-navigator`; Herdr uses the upstream
`paulbkim-dev/vim-herdr-navigation` workflow plugin. Its Herdr action forwards
the key when Neovim is in the foreground and otherwise focuses the neighboring
Herdr pane. Inside Neovim, its editor integration moves between windows first
and invokes `herdr pane focus` only at an outer edge.

The Lazy plugin spec selects the integration from the session environment:
`HERDR_ENV`, `HERDR_PANE_ID`, and `HERDR_SOCKET_PATH` load
`vim-herdr-navigation`; all other sessions load
`christoomey/vim-tmux-navigator`. Without tmux, that plugin moves between
Neovim windows directly, including in herdr-app terminals backed by herdr-core.
Envy installs the matching Herdr workflow plugin. Herdr takes precedence if
stale or nested tmux environment variables are also present.

Herdr app uses `Cmd-h/j/k/l` for app pane navigation, leaving
`Ctrl-h/j/k/l` available to Neovim. Dotfiles setup links
`config/herdr-app/keys.json` and `config/herdr-app/settings.json` into
`${HERDR_APP_HOME:-~/.config/herdr-app}`; the updater repairs those links.
Edit the repository files to change app preferences. Differing existing files
are preserved with a warning; merge wanted settings, back up and move the
conflicting files aside, then rerun setup.

Use repository edits rather than the app Settings UI for managed preferences.
The UI saves settings with an atomic file replacement, which can replace a
symlink instead of updating its target. If a managed file becomes a regular
file, merge wanted changes into the repository, back up and move that file
aside, then run `./bin/envy install local.herdr_app@r0` to restore the link.

Plain `ctrl-h/j/k/l` bindings to `pane.go` intercept keys before Neovim and
are intentionally absent. Prefixed `Ctrl-a` navigation remains available.
`Cmd-h` replaces the app's Hide shortcut. Changes reload automatically.
Neovim window edges do not hand off to app panes; use the `Cmd` shortcuts.

Check Neovim window navigation with installed plugins from the repository root:

```sh
env -u TMUX -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH \
  nvim --headless -u NONE -l nvim/tests/navigation_spec.lua
```

The following bindings remain tmux-only:

- `Ctrl-a :`, `Ctrl-a r`, and `Ctrl-a L`: Herdr has no command prompt,
  client-refresh operation, or history-clear operation.
- `Ctrl-a .`, `Ctrl-a ,`, and `Ctrl-a m`: tmux layout presets cannot safely
  rearrange Herdr's live pane processes.
- `Ctrl-a y`: tmux-yank captures an editable shell command line that Herdr's
  pane API cannot reliably derive.
- `Ctrl-a a`, `Ctrl-a Ctrl-o`, `Ctrl-a 0`, `Ctrl-a ]`, and `Ctrl-a Shift-y`:
  last-pane, rotation, first-pane swapping, clipboard paste, and working-directory
  copy are not bound in the current Herdr configuration.
- TPM and resurrect controls: Herdr manages persistence and integrations
  independently.
- Rectangle selection: Herdr copy mode already supports `v`, Space, `y`, and
  Enter, but has no tmux rectangle-selection equivalent.
- Mouse bindings, which are outside this keyboard-parity audit.

`scripts/herdr-tmux-action` remains available for manual rotation, first-pane
swapping, literal system-clipboard paste, and foreground-working-directory copy.
It is not bound in the current Herdr configuration. Runtime races, missing
clipboard tools, stale panes, and single-pane layouts silently no-op. macOS uses
`pbcopy` / `pbpaste`; supported Linux profiles install `wl-clipboard`.
