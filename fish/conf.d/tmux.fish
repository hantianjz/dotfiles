function tmux-from-session-name
  tmux -2 new-session -As $argv[1]
end

function new-tmux-from-dir-name
  tmux-from-session-name (basename $PWD)
end

function __tmux-list-sessions
  tmux list-sessions -F "#{session_name}"
end

alias tmn "new-tmux-from-dir-name"
alias tma 'tmux-from-session-name'
alias tml 'tmux list-sessions'

complete -f -x -c tma -a "(__tmux-list-sessions)"