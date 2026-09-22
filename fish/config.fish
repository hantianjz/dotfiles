if status is-interactive
    set fish_greeting

    if type -q zoxide
        zoxide init fish | source
    end

    for _f in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish
        test -r "$_f"; and source "$_f"; and break
    end
end

set fzf_fd_opts --type f --hidden --follow
set fzf_git_log_opts --height=100%
set fzf_history_opts --layout=default --height=50%

set -l envy_hook
switch (uname)
    case Linux
        set envy_hook "$HOME/.cache/envy/shell/hook.fish"
    case Darwin
        set envy_hook "$HOME/Library/Caches/envy/shell/hook.fish"
end

if test -r "$envy_hook"
    if not status is-interactive; and not set -q ENVY_SHELL_NO_ENTER_EXIT_ANNOUNCE
        set -gx ENVY_SHELL_NO_ENTER_EXIT_ANNOUNCE 1
    end
    source "$envy_hook"
end
