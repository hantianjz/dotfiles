# Herdr app and Neovim navigation

Inside Neovim, `Ctrl-h/j/k/l` uses native window navigation in normal and
terminal modes. These keys never hand off to Herdr or tmux panes, including
at a Neovim window edge. No multiplexer navigation plugin is loaded.

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
are intentionally absent. `Cmd-Shift-h/j/k/l` swaps app panes; AeroSpace
leaves these shortcuts unbound. `Ctrl-a v` and `Ctrl-a s` split panes;
`Ctrl-a n` and `Ctrl-a p` select agents. Changes reload automatically.
Neovim window edges do not hand off to app panes; use the `Cmd` shortcuts.

In Herdr app, `Ctrl-a [` starts a text selection at the terminal cursor;
`Cmd-c` copies the selection. This does not enter a modal copy mode or
change the existing pane navigation bindings.

Check native Neovim window navigation from the repository root:

```sh
nvim --headless -u NONE -l nvim/tests/navigation_spec.lua
```


`scripts/herdr-tmux-action` remains available for manual rotation, first-pane
swapping, literal system-clipboard paste, and foreground-working-directory copy.
It is not bound by the managed Herdr app shortcuts. Runtime races, missing
clipboard tools, stale panes, and single-pane layouts silently no-op. macOS uses
`pbcopy` / `pbpaste`; supported Linux profiles install `wl-clipboard`.
