# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/hjz/.docker/bin"
# End of Docker Desktop section.

if status is-interactive
    set fish_greeting

    if type -q zoxide
        zoxide init fish | source
    end

    if type -q jq; and test -r "$HOME/.config/herdr/plugins.json"
        for _f in (jq -r '.[] | select(.source.kind == "github" and .source.owner == "qu8n" and .source.repo == "herdr-automatic-rename") | .plugin_root // empty' "$HOME/.config/herdr/plugins.json" 2>/dev/null)
            test -r "$_f/shell/hook.fish"; and source "$_f/shell/hook.fish"; and break
        end
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
