function tmux-from-session-name
  set -e DEACTIVATED_HERMIT
  if test -n "$HERMIT_ENV"
      type -q _hermit_deactivate; and _hermit_deactivate
  end
  tmx open $argv[1]
end

function new-tmux-from-dir-name
  tmux-from-session-name (basename $PWD)
end

alias t 'tmx'
alias tmn "new-tmux-from-dir-name"
alias tma 't o'
alias tml 't ls'
