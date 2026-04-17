# t -- fzf picker, field setter, and todo.sh wrapper
#
# A lightweight switchboard for resuming agent sessions and
# jumping between projects. Natively handles the fzf picker and
# targeted field updates; passes everything else through to
# todo.sh (the official todo.txt CLI).
#
# Data: ~/.tasks/todo.txt and ~/.tasks/done.txt
#       (paths match ~/.todo.cfg)
#
# Native commands:
#   t                     fzf picker over active tasks (todo.txt)
#   t --done              picker over archived tasks (done.txt)
#   t --all               picker over both files combined
#   t set <id> <k> <v>    update a field on the matching task
#                           (dir ~ collapse, +project syntax,
#                            (A) priority prefix)
#   t -h / t --help       show this help + todo.sh help
#
# Everything else (add, do, archive, ls, pri, rm, replace, ...)
# is passed through to todo.sh. Examples:
#   t add "Fix the thing +proj"
#   t do 3
#   t archive
#   t ls @backend
#
# Pick keybindings:
#   enter     Resume agent session. Dispatches by agent: field
#             (claude by default, codex if agent:codex).
#             cd's to dir: first (sessions are project-scoped).
#   ctrl-e    Open todo.txt in $EDITOR
#   ctrl-d    cd to task directory
#   ctrl-o    Open ticket in browser
#   ctrl-x    Mark done (delegates to `todo.sh do N`)
#
# Agent field: agent:claude (default) or agent:codex

function __t_field --description 'Extract key:value from a todo.txt line'
    set -l match (string match -r -- "$argv[1]:(\\S+)" $argv[2])
    and echo $match[2]
end

function __t_find --description 'Find task line number in todo.txt by identifier'
    set -l identifier $argv[1]
    set -l tasks_file ~/.tasks/todo.txt

    set -l matches
    set -l line_num 0
    while read -l line
        set line_num (math $line_num + 1)
        if string match -qi -- "*$identifier*" $line
            set -a matches $line_num
        end
    end <$tasks_file

    switch (count $matches)
        case 0
            echo "No task matching '$identifier'" >&2
            return 1
        case 1
            echo $matches[1]
        case '*'
            echo "Multiple tasks match '$identifier':" >&2
            for num in $matches
                sed -n "$num"p $tasks_file | read -l text
                echo "  $num: $text" >&2
            end
            echo "Be more specific." >&2
            return 1
    end
end

function __t_replace_line --description 'Replace line N in todo.txt atomically'
    set -l line_num $argv[1]
    set -l new_content $argv[2]
    set -l tasks_file ~/.tasks/todo.txt
    set -l tmp (mktemp)

    set -l current 0
    while read -l line
        set current (math $current + 1)
        if test $current -eq $line_num
            echo $new_content
        else
            echo $line
        end
    end <$tasks_file >$tmp

    command mv -f $tmp $tasks_file
end

function __t_set_field --description 'Set or add a key:value field on a line'
    set -l line $argv[1]
    set -l key $argv[2]
    set -l value $argv[3]

    if string match -q -- "*$key:*" $line
        string replace -r -- "$key:\\S+" "$key:$value" $line
    else
        echo "$line $key:$value"
    end
end

function __t_set --description 't set implementation'
    if test (count $argv) -lt 3
        echo "Usage: t set <identifier> <key> <value>" >&2
        return 1
    end
    set -l tasks_file ~/.tasks/todo.txt
    set -l target (__t_find $argv[1])
    or return 1

    set -l line (sed -n "$target"p $tasks_file)
    set -l updated

    switch $argv[2]
        case priority
            set updated (string replace -r '^\([A-Z]\) ' '' -- $line)
            if test -n "$argv[3]"
                set updated "($argv[3]) $updated"
            end
        case project
            set updated (string replace -r ' \+\S+' '' -- $line)
            if string match -qr ' \S+:\S+' -- $updated
                set updated (
                    string replace -r ' (\S+:\S+)' \
                        " +$argv[3] \$1" -- $updated
                )
            else
                set updated "$updated +$argv[3]"
            end
        case dir
            set -l value (string replace -- $HOME '~' $argv[3])
            set updated (__t_set_field "$line" dir $value)
        case '*'
            set updated (__t_set_field "$line" $argv[2] $argv[3])
    end

    __t_replace_line $target $updated
    echo "Updated: $updated"
end

function __t_help --description 't extensions + todo.sh help'
    echo "t extensions:"
    echo "  t                     fzf picker over active tasks"
    echo "  t --done              picker over done.txt"
    echo "  t --all               picker over todo.txt + done.txt"
    echo "  t set <id> <k> <v>    targeted field update"
    echo "                          (dir ~ collapse, +project,"
    echo "                           (A) priority prefix)"
    echo ""
    echo "Pick keybindings:"
    echo "  enter   resume agent (claude/codex)  ctrl-d   cd"
    echo "  ctrl-e  edit todo.txt                ctrl-o   ticket"
    echo "  ctrl-x  mark done"
    echo ""
    echo "Any other invocation passes through to todo.sh."
    echo "--- todo.sh help ---"
    todo.sh -h 2>&1
end

function __t_pick --description 'fzf picker: active | done | all'
    set -l source $argv[1]
    set -l tasks_file ~/.tasks/todo.txt
    set -l done_file ~/.tasks/done.txt

    set -l source_files
    switch $source
        case active
            set source_files $tasks_file
        case done
            set source_files $done_file
        case all
            set source_files $tasks_file $done_file
    end

    set -l all_lines
    for file in $source_files
        test -f $file; or continue
        while read -l line
            test -z "$line"; and continue
            set -a all_lines $line
        end <$file
    end

    if test (count $all_lines) -eq 0
        echo "No tasks in $source."
        return 0
    end

    set -l header "enter:resume  ctrl-e:edit  ctrl-d:cd  ctrl-o:ticket  ctrl-x:done"
    set -l result (
        printf '%s\n' $all_lines \
            | fzf --expect 'ctrl-e,ctrl-d,ctrl-o,ctrl-x' \
                  --header "$header" \
                  --no-sort \
                  --reverse
    )

    test -z "$result"; and return 0
    set -l key $result[1]
    set -l selection $result[2]
    test -z "$selection"; and return 0

    switch "$key"
        case ''
            # Enter -- resume session (cd first; sessions are project-scoped)
            set -l d (__t_field dir "$selection")
            if test -n "$d"
                cd (string replace -- '~' $HOME $d)
            end
            set -l sess (__t_field session "$selection")
            if test -z "$sess"
                if test -n "$d"
                    echo "No session. Changed to "(pwd)
                else
                    echo "No session or directory on this task."
                end
                return 0
            end
            set -l agent (__t_field agent "$selection")
            switch "$agent"
                case '' claude
                    claude --resume $sess
                case codex
                    codex resume $sess
                case '*'
                    echo "Unknown agent: $agent. Changed to "(pwd)
            end

        case ctrl-e
            if test -n "$EDITOR"
                $EDITOR $tasks_file
            else
                nvim $tasks_file
            end

        case ctrl-d
            set -l d (__t_field dir "$selection")
            if test -n "$d"
                cd (string replace -- '~' $HOME $d)
                pwd
            else
                echo "No directory on this task."
            end

        case ctrl-o
            set -l ticket (__t_field ticket "$selection")
            if test -z "$ticket"
                set ticket (__t_field jira "$selection")
            end
            if test -z "$ticket"
                echo "No ticket on this task."
                return 0
            end
            set -l url (
                linear-cli i get $ticket -o json 2>/dev/null \
                    | jq -r '.url // empty'
            )
            if test -n "$url"
                open $url
            else
                acli jira workitem view $ticket --web 2>/dev/null
                or echo "Could not open $ticket" >&2
            end

        case ctrl-x
            # Find the selected line in todo.txt and delegate to todo.sh
            set -l line_num 0
            set -l found 0
            while read -l line
                set line_num (math $line_num + 1)
                if test "$line" = "$selection"
                    set found 1
                    break
                end
            end <$tasks_file
            if test $found -eq 1
                todo.sh do $line_num
            else
                echo "Task not in todo.txt (already archived?)." >&2
            end
    end
end

function t --description 'Task registry -- picker + setter + todo.sh wrapper'
    set -l tasks_dir ~/.tasks
    if not test -d $tasks_dir
        mkdir -p $tasks_dir
    end
    if not test -f $tasks_dir/todo.txt
        touch $tasks_dir/todo.txt
    end

    # No args -- picker over active
    if test (count $argv) -eq 0
        __t_pick active
        return
    end

    # Native handling based on first arg
    switch "$argv[1]"
        case --done
            if test (count $argv) -gt 1
                echo "t --done takes no additional arguments" >&2
                return 1
            end
            __t_pick done
            return
        case --all
            if test (count $argv) -gt 1
                echo "t --all takes no additional arguments" >&2
                return 1
            end
            __t_pick all
            return
        case -h --help
            __t_help
            return
        case set
            __t_set $argv[2..]
            return
    end

    # Pass-through to todo.sh
    todo.sh $argv
end
