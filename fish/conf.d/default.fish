alias l 'ls -Gal'
alias ll "ls -Ghal"

alias vim 'nvim'
alias v 'nvim'

alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."

alias pg "ps ax | grep -v grep | grep -i "
alias df 'df -h'
alias df='df -h'
alias diffu='diff --unified'
alias du='du -kh'
alias ducks='du -cksh * | sort -rn|head -11'
alias profileme "history | awk '{print \$4}' | awk 'BEGIN{FS=\"|\"}{print \$1}' | sort | uniq -c | sort -n | tail -n 20 | sort -nr"

alias jsformat "python -mjson.tool"

alias n "nnn -dEeQrux"
alias nnn "nnn -dEeQrux"

alias mkdir 'mkdir -p'
alias o 'open'
alias pbc pbcopy
alias pbp pbpaste
alias pg 'ps ax | grep -v grep | grep -i '
