complete -c t -f

complete -c t -n __fish_use_subcommand -a set -d 'Set a field on a task'
complete -c t -n __fish_use_subcommand -l done -d 'Picker over done.txt'
complete -c t -n __fish_use_subcommand -l all -d 'Picker over todo.txt + done.txt'
