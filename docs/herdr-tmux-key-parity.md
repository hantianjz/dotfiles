# Herdr–tmux key parity

`config/herdr/config.toml` mirrors the personal prefix bindings in
`tmux/tmux.keys.conf` when Herdr has an exact or deterministic equivalent.
It also includes tmux-sensible's `Ctrl-a Ctrl-p` / `Ctrl-a Ctrl-n` window
navigation and tmux-yank's `Ctrl-a Shift-y` working-directory copy.

Herdr keeps `Ctrl-a b` for its sidebar. This intentionally differs from
tmux-sensible's last-window binding. Herdr and tmux are configured as
independent multiplexers and are not intended to be nested. Herdr's built-in
double-prefix behavior sends a literal `Ctrl-a` to the active program.

Direct `Ctrl-h/j/k/l` is process-aware in both multiplexers. tmux uses
`vim-tmux-navigator`; Herdr uses `scripts/herdr-nvim-navigator` plus the local
`nvim/lua/herdr_navigator.lua` module. The Herdr router forwards the key when
Neovim is in the foreground and otherwise focuses the neighboring Herdr pane.
Inside Neovim, the local navigator moves between windows first and invokes
`herdr pane focus` only at an outer edge.

The Lazy plugin spec selects the integration from the session environment:
`HERDR_ENV`, `HERDR_PANE_ID`, and `HERDR_SOCKET_PATH` load the local Herdr
navigator; other sessions keep `christoomey/vim-tmux-navigator`. Herdr takes
precedence if stale or nested tmux environment variables are also present.

The following bindings remain tmux-only:

- `Ctrl-a :`, `Ctrl-a r`, and `Ctrl-a L`: Herdr has no command prompt,
  client-refresh operation, or history-clear operation.
- `Ctrl-a .`, `Ctrl-a ,`, and `Ctrl-a m`: tmux layout presets cannot safely
  rearrange Herdr's live pane processes.
- `Ctrl-a y`: tmux-yank captures an editable shell command line that Herdr's
  pane API cannot reliably derive.
- TPM and resurrect controls: Herdr manages persistence and integrations
  independently.
- Rectangle selection: Herdr copy mode already supports `v`, Space, `y`, and
  Enter, but has no tmux rectangle-selection equivalent.
- Mouse bindings, which are outside this keyboard-parity audit.

`scripts/herdr-tmux-action` supplies rotation, first-pane swapping, literal
system-clipboard paste, and foreground-working-directory copy. Runtime races,
missing clipboard tools, stale panes, and single-pane layouts silently no-op.
macOS uses `pbcopy` / `pbpaste`; supported Linux profiles install
`wl-clipboard`.
