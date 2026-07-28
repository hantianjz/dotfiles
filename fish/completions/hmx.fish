# Fish completions for hmx
complete -c hmx -f
complete -c hmx -s c -l config -r -d 'Path to shared tmx config'
complete -c hmx -l remote -r -d 'SSH target'
complete -c hmx -l session -r -d 'Herdr session'
complete -c hmx -s v -l verbose -d 'Print commands'
complete -c hmx -n '__fish_use_subcommand' -a open -d 'Open or focus a workspace'
complete -c hmx -n '__fish_use_subcommand' -a close -d 'Close a workspace'
complete -c hmx -n '__fish_use_subcommand' -a refresh -d 'Refresh a workspace'
complete -c hmx -n '__fish_use_subcommand' -a list -d 'List workspaces'
complete -c hmx -n '__fish_use_subcommand' -a init
complete -c hmx -n '__fish_use_subcommand' -a validate
complete -c hmx -n '__fish_use_subcommand' -a completions
complete -c hmx -n '__fish_seen_subcommand_from open o' -a '(hmx __list-configured; hmx __list-running)'
complete -c hmx -n '__fish_seen_subcommand_from close c refresh r' -a '(hmx __list-running)'
complete -c hmx -n '__fish_seen_subcommand_from completions' -a 'bash fish zsh'
