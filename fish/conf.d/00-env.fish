set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'
set -gx AIDER_EDITOR 'nvim'
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx MANPAGER 'nvim +Man!'
set -gx FZF_DEFAULT_OPTS --cycle --border --preview-window=wrap --marker="*" --height=75% --layout=reverse

set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path --global --move "$HOME/.local/bin" "$HOME/bin" "$HOME/.cargo/bin" "$HOME/.bun/bin"

if test -r "$HOME/.config/local_config.fish"
    source "$HOME/.config/local_config.fish"
end
