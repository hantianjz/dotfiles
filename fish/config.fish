if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
end

set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'
set -gx XDG_CONFIG_HOME ~/.config/

set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

set LOCAL_FISH_CONFIG ~/.config/local_config.fish
if test -f $LOCAL_FISH_CONFIG
  source $LOCAL_FISH_CONFIG
end
