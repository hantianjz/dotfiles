if type -q nvim
  alias vim 'nvim'
  alias v 'nvim'
  alias n 'nvim .'
end

if type -q eza
  alias ls 'eza'
end

alias l 'ls -Gal'
alias ll "ls -Ghal"

if type -q batcat
  alias cat 'batcat'
end

if type -q bat
  alias cat 'bat'
end

if type -q fdfind
    alias fd 'fdfind'
end

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

alias mkdir 'mkdir -p'
alias o 'open'
if type -q pbcopy
  alias pbc pbcopy
end
if type -q pbpaste
  alias pbp pbpaste
end
alias pg 'ps ax | grep -v grep | grep -i '

alias po 'prevd'
alias popd 'prevd'
