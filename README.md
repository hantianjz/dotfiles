# Program to install
- brew (macos)
- rust-cargo
- kitty
- tmux
- zsh
- neovim
- i3
- i3-lock
- rofi
- polybar
- nnn
- fzf
- git

# Setup PATH
- python local pip executable

# Rust Cargo installs
bat
cargo-update
diskus
fd-find
gping
hexyl
ripgrep

# Brew install (macos)
- `brew install koekeishiya/formulae/yabai`
- https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)
- `brew install koekeishiya/formulae/skhd`
- `brew install wader/tap/fq`
- `brew install jq`
- `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- `curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin`

# TODO
- [ ] Update vimrc allow temp disable linting $dotfile
    - By repo
    - or by nearby config file
- [ ] Setup tmux layout configurations $dotfile
    - For split view with 2 pane
    - for half view with 3 pane + more
    - for focus on vim, detect pane type and place in correct layout
- [ ] Fix python3 paths $dotfile
    - also `python` alias 
- [ ] build a pip install list $dotfile
- [ ] need a refresh checklist, and maybe script $dotfile
    - Update vim plugins
    - `cargo install-update -a`
    - brew upgrade
    - update kitty
    - update prezeto

