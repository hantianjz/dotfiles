if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
end

set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'
set -gx AIDER_EDITOR 'nvim'
set -gx XDG_CONFIG_HOME ~/.config/

set -gx MANPAGER 'nvim +Man!'

set -gx FZF_DEFAULT_OPTS --cycle --border --preview-window=wrap --marker="*" --height=75% --layout=reverse

set fzf_fd_opts --type f --hidden --follow

set fzf_git_log_opts --height=100%
set fzf_history_opts --layout=default --height=50%

set LOCAL_FISH_CONFIG ~/.config/local_config.fish
if test -f $LOCAL_FISH_CONFIG
  source $LOCAL_FISH_CONFIG
end

if type -q zoxide
  zoxide init fish | source
end
