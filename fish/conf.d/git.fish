#
# Aliases
#
set _git_log_medium_format '%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B'
set _git_log_oneline_format '%C(green)%h%C(reset) %C(red)%d%C(reset) %s %Cgreen(%ad) %C(bold blue)<%an>%Creset%n'
set _git_log_brief_format '%C(green)%h%C(reset) %s%n%C(blue)(%ar by %an)%C(red)%d%C(reset)%n'

# Status
set _git_status_ignore_submodules 'none'

# Branch (b)
alias gb 'git branch'
alias gbc 'git checkout -b'
alias gbl 'git branch -v'
alias gbL 'git branch -av'
alias gbx 'git branch -d'
alias gbX 'git branch -D'
alias gbm 'git branch -m'
alias gbM 'git branch -M'
alias gbs 'git show-branch'
alias gbS 'git show-branch -a'

# Commit (c)
alias gc 'git commit --verbose'
alias gca 'git commit --verbose --all'
alias gco 'git checkout'
alias gcf 'git commit --amend --reuse-message HEAD'
alias gcp 'git cherry-pick'
alias gcr 'git revert'
alias gcs 'git show'
# alias gcl 'git-commit-lost'

# Fetch (f)
alias gf 'git fetch'
alias gfc 'git clone'
alias gfm 'git pull'
alias gfr 'git pull --rebase'

# Index (i)
alias gia 'git add'
alias gai 'git add'
alias gap 'git add --patch'

# Log (l)
alias gl 'git log --topo-order --pretty=format:"$_git_log_medium_format"'
alias gls 'git log --topo-order --stat --pretty=format:"$_git_log_medium_format}"'
alias gld 'git log --topo-order --stat --patch --full-diff --pretty format:"$_git_log_medium_format"'
alias glo 'git log --topo-order --pretty=format:"$_git_log_oneline_format"'
alias glg 'git log --topo-order --all --graph --pretty format:"$_git_log_oneline_format"'
alias glb 'git log --topo-order --pretty=format:"$_git_log_brief_format"'
alias glc 'git shortlog --summary --numbered'

# Merge (m)
alias gm 'git merge'
alias gma 'git merge --abort'

# Push (p)
alias gp 'git push'
alias gpf 'git push --force'

# Rebase (r)
alias gr 'git rebase'
alias gra 'git rebase --abort'
alias grc 'git rebase --continue'
alias gri 'git rebase --interactive'
alias grs 'git rebase --skip'

# Stash (s)
alias gs 'git stash'
alias gsa 'git stash apply'
# alias gsx 'git stash drop'
# alias gsX 'git-stash-clear-interactive'
alias gsl 'git stash list'
# alias gsL 'git-stash-dropped'
# alias gsd 'git stash show --patch --stat'
# alias gsp 'git stash pop'
# alias gsr 'git-stash-recover'
# alias gss 'git stash save --include-untracked'
# alias gsS 'git stash save --patch --no-keep-index'
# alias gsw 'git stash save --include-untracked --keep-index'

# Submodule (S)
alias gS 'git submodule'
# alias gSa 'git submodule add'
# alias gSf 'git submodule foreach'
# alias gSi 'git submodule init'
alias gSI 'git submodule update --init --recursive'
# alias gSl 'git submodule status'
# alias gSm 'git-submodule-move'
# alias gSs 'git submodule sync'
alias gSu 'git submodule foreach git pull origin master'
# alias gSx 'git-submodule-remove'

# Working Copy (w)
alias gws 'git status --ignore-submodules $_git_status_ignore_submodules --short'
alias gwS 'git status --ignore-submodules $_git_status_ignore_submodules'
alias gwd 'git diff --no-ext-diff'
alias gwr 'git reset --soft'
alias gwR 'git reset --hard'
alias gclean "git clean -dff && git submodule foreach git clean -dff"

alias gis 'git status'
alias ghd 'git show HEAD'
