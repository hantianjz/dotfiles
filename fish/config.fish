if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
end

set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'

set LOCAL_FISH_CONFIG ~/.config/local_config.fish
if test -f $LOCAL_FISH_CONFIG
  source $LOCAL_FISH_CONFIG
end
