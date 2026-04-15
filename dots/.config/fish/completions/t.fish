complete -c t -f

complete -c t -n __fish_use_subcommand -a add -d 'Add a task'
complete -c t -n __fish_use_subcommand -a pick -d 'Interactive picker'
complete -c t -n __fish_use_subcommand -a list -d 'List tasks'
complete -c t -n __fish_use_subcommand -a done -d 'Mark task done'
complete -c t -n __fish_use_subcommand -a status -d 'Change task status'
complete -c t -n __fish_use_subcommand -a session -d 'Set session ID'
complete -c t -n __fish_use_subcommand -a set -d 'Set any key:value field'
complete -c t -n __fish_use_subcommand -a edit -d 'Edit todo.txt'
complete -c t -n __fish_use_subcommand -a rm -d 'Remove a task'
complete -c t -n __fish_use_subcommand -a help -d 'Show help'

complete -c t -n '__fish_seen_subcommand_from add' -l jira -s j -d 'Jira ticket'
complete -c t -n '__fish_seen_subcommand_from add' -l dir -d 'Working directory'
complete -c t -n '__fish_seen_subcommand_from add' -l session -s s -d 'Session ID'
complete -c t -n '__fish_seen_subcommand_from add' -l priority -s p -d 'Priority A-Z'
complete -c t -n '__fish_seen_subcommand_from add' -l project -d 'Project name'
complete -c t -n '__fish_seen_subcommand_from add' -l status -d 'Initial status'

complete -c t -n '__fish_seen_subcommand_from list' -l all -s a -d 'Include done'
complete -c t -n '__fish_seen_subcommand_from list' -l project -d 'Filter by project'
complete -c t -n '__fish_seen_subcommand_from list' -l status -d 'Filter by status'
