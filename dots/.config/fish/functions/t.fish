# t -- task registry for tracking work across projects
#
# A lightweight index for resuming agent sessions and jumping
# between projects. Not a task manager -- Linear, Slack, etc.
# remain the systems of record. This is the switchboard.
#
# Data: ~/.tasks/todo.txt (standard todo.txt format)
#
# Subcommands:
#   t                           Interactive fzf picker (default)
#   t add "summary" [flags]     Add a task
#     --ticket, -t KEY          Linear ticket (auto-fetches title)
#     --dir PATH                Working directory
#     --session, -s ID          Agent session ID
#     --priority, -p X          Priority A-Z
#     --project NAME            Project (+tag); auto-detects from
#                               git remote when omitted
#     --status STATUS           Initial status (default: active)
#   t list [--all] [--project X] [--status X]
#   t done <id>                 Mark task done
#   t status <id> <status>      Change status (active/paused/blocked)
#   t session <id> <session_id> Set/update session ID
#   t set <id> <key> <value>    Set any key:value field
#   t edit                      Open todo.txt in $EDITOR
#   t rm <id>                   Remove a task (searches all incl. done)
#   t help                      Usage
#
# The <id> argument is a substring match -- "ACT-456", "flux",
# "Billing" all work. Errors on ambiguous matches.
#
# Pick keybindings (t pick / t):
#   enter     Resume agent session. Dispatches by agent: field
#             (claude by default, codex if agent:codex).
#             cd's to dir: first (sessions are project-scoped).
#             Falls back to cd if no session is set.
#   ctrl-e    Open todo.txt in $EDITOR
#   ctrl-d    cd to task directory
#   ctrl-o    Open ticket in browser (via linear-cli)
#   ctrl-x    Mark task done
#
#   The picker shows ALL tasks (including done) so completed
#   sessions remain resumable for follow-up work.
#
# Agent field:
#   Add agent:<name> to a task line to control how sessions
#   resume. Supported: claude (default), codex.
#
# Agent interface:
#   Any agent or script can skip the fish function and append
#   a todo.txt line directly:
#
#   echo "(A) 2026-04-07 Fix thing status:active session:SESS \
#     dir:~/git/web ticket:ACT-456 agent:codex" >> ~/.tasks/todo.txt

function __t_field --description 'Extract key:value from a todo.txt line'
    set -l match (string match -r -- "$argv[1]:(\\S+)" $argv[2])
    and echo $match[2]
end

function __t_find --description 'Find task line number by identifier'
    set -l search_all 0
    if test "$argv[1]" = --all
        set search_all 1
        set -e argv[1]
    end
    set -l identifier $argv[1]
    set -l tasks_file ~/.tasks/todo.txt

    set -l matches
    set -l line_num 0
    while read -l line
        set line_num (math $line_num + 1)
        if test $search_all -eq 0; and string match -q 'x *' -- $line
            continue
        end
        if string match -qi -- "*$identifier*" $line
            set -a matches $line_num
        end
    end <$tasks_file

    switch (count $matches)
        case 0
            echo "No active task matching '$identifier'" >&2
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

function __t_remove_line --description 'Remove line N from todo.txt atomically'
    set -l line_num $argv[1]
    set -l tasks_file ~/.tasks/todo.txt
    set -l tmp (mktemp)

    set -l current 0
    while read -l line
        set current (math $current + 1)
        if test $current -ne $line_num
            echo $line
        end
    end <$tasks_file >$tmp

    command mv -f $tmp $tasks_file
end

function __t_set_field --description 'Set or add a key:value field on a todo.txt line'
    set -l line $argv[1]
    set -l key $argv[2]
    set -l value $argv[3]

    if string match -q -- "*$key:*" $line
        string replace -r -- "$key:\\S+" "$key:$value" $line
    else
        echo "$line $key:$value"
    end
end

function t --description 'Task registry -- track work across projects'
    set -l tasks_dir ~/.tasks
    set -l tasks_file $tasks_dir/todo.txt

    if not test -d $tasks_dir
        mkdir -p $tasks_dir
    end
    if not test -f $tasks_file
        touch $tasks_file
    end

    switch "$argv[1]"

        # -- add --------------------------------------------------------
        case add
            set -l args $argv[2..]
            set -l summary
            set -l ticket
            set -l dir
            set -l session
            set -l priority
            set -l project
            set -l task_status active

            set -l i 1
            while test $i -le (count $args)
                switch $args[$i]
                    case --ticket -t
                        set i (math $i + 1)
                        set ticket $args[$i]
                    case --dir
                        set i (math $i + 1)
                        set dir $args[$i]
                    case --session -s
                        set i (math $i + 1)
                        set session $args[$i]
                    case --priority -p
                        set i (math $i + 1)
                        set priority $args[$i]
                    case --project
                        set i (math $i + 1)
                        set project $args[$i]
                    case --status
                        set i (math $i + 1)
                        set task_status $args[$i]
                    case '-*'
                        echo "Unknown flag: $args[$i]" >&2
                        return 1
                    case '*'
                        if test -z "$summary"
                            set summary $args[$i]
                        else
                            echo "Unexpected argument: $args[$i]" >&2
                            return 1
                        end
                end
                set i (math $i + 1)
            end

            # Auto-fetch title from Linear when omitted
            if test -z "$summary"; and test -n "$ticket"
                set summary (
                    linear-cli i get $ticket -o json 2>/dev/null \
                        | jq -r '.title // empty'
                )
            end
            if test -z "$summary"
                read -P "Summary: " summary
            end
            if test -z "$summary"
                echo "Summary is required." >&2
                return 1
            end

            # Auto-detect project from git remote when omitted
            if test -z "$project"
                set project (
                    git remote get-url origin 2>/dev/null \
                        | string replace -r '.*[:/](.+/.+?)(?:\.git)?$' '$1'
                )
            end

            # Build the todo.txt line
            set -l line
            if test -n "$priority"
                set line "($priority) "
            end
            set line "$line"(date +%Y-%m-%d)" $summary"
            if test -n "$project"
                set line "$line +$project"
            end
            set line "$line status:$task_status"
            if test -n "$session"
                set line "$line session:$session"
            end
            if test -n "$dir"
                set line "$line dir:"(string replace -- $HOME '~' $dir)
            end
            if test -n "$ticket"
                set line "$line ticket:$ticket"
            end

            echo $line >>$tasks_file
            echo $line

            # -- pick (default) -----------------------------------------
        case pick ''
            set -l all_tasks
            set -l line_nums
            set -l line_num 0
            while read -l line
                set line_num (math $line_num + 1)
                test -z "$line"; and continue
                set -a all_tasks $line
                set -a line_nums $line_num
            end <$tasks_file

            if test (count $all_tasks) -eq 0
                echo "No tasks."
                return 0
            end

            set -l header "enter:resume  ctrl-e:edit  ctrl-d:cd  ctrl-o:open  ctrl-x:done"
            set -l result (
                printf '%s\n' $all_tasks \
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
                    # Enter -- resume session
                    # cd to task dir first (sessions are project-scoped)
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
                    set -l tk (__t_field ticket "$selection")
                    if test -n "$tk"
                        linear-cli issues open $tk 2>/dev/null
                        or echo "Could not open $tk" >&2
                    else
                        echo "No ticket on this task."
                    end

                case ctrl-x
                    for idx in (seq (count $all_tasks))
                        if test "$all_tasks[$idx]" = "$selection"
                            set -l target $line_nums[$idx]
                            set -l updated (
                                string replace -r 'status:\\S+' 'status:done' \
                                    -- $selection
                            )
                            if not string match -q '*status:*' -- $updated
                                set updated "$updated status:done"
                            end
                            __t_replace_line $target "x "(date +%Y-%m-%d)" $updated"
                            echo "Done: $selection"
                            break
                        end
                    end
            end

            # -- list ---------------------------------------------------
        case list ls
            set -l show_all 0
            set -l filter_project
            set -l filter_status
            set -l args $argv[2..]

            set -l i 1
            while test $i -le (count $args)
                switch $args[$i]
                    case --all -a
                        set show_all 1
                    case --project
                        set i (math $i + 1)
                        set filter_project $args[$i]
                    case --status
                        set i (math $i + 1)
                        set filter_status $args[$i]
                    case '*'
                        echo "Unknown: $args[$i]" >&2
                        return 1
                end
                set i (math $i + 1)
            end

            while read -l line
                if test $show_all -eq 0
                    string match -q 'x *' -- $line; and continue
                end
                if test -n "$filter_project"
                    string match -qi -- "*+$filter_project*" $line
                    or continue
                end
                if test -n "$filter_status"
                    string match -qi -- "*status:$filter_status*" $line
                    or continue
                end
                echo $line
            end <$tasks_file

            # -- done ---------------------------------------------------
        case done
            if not set -q argv[2]
                echo "Usage: t done <identifier>" >&2
                return 1
            end
            set -l target (__t_find $argv[2])
            or return 1

            set -l line (sed -n "$target"p $tasks_file)
            set -l updated (
                string replace -r 'status:\\S+' 'status:done' -- $line
            )
            if not string match -q '*status:*' -- $updated
                set updated "$updated status:done"
            end
            __t_replace_line $target "x "(date +%Y-%m-%d)" $updated"
            echo "Done: $line"

            # -- status -------------------------------------------------
        case status
            if test (count $argv) -lt 3
                echo "Usage: t status <identifier> <new_status>" >&2
                return 1
            end
            set -l target (__t_find $argv[2])
            or return 1

            set -l line (sed -n "$target"p $tasks_file)
            set -l updated (__t_set_field "$line" status $argv[3])
            __t_replace_line $target $updated
            echo "Updated: $updated"

            # -- session ------------------------------------------------
        case session
            if test (count $argv) -lt 3
                echo "Usage: t session <identifier> <session_id>" >&2
                return 1
            end
            set -l target (__t_find $argv[2])
            or return 1

            set -l line (sed -n "$target"p $tasks_file)
            set -l updated (__t_set_field "$line" session $argv[3])
            __t_replace_line $target $updated
            echo "Updated: $updated"

            # -- set ----------------------------------------------------
        case set
            if test (count $argv) -lt 4
                echo "Usage: t set <identifier> <key> <value>" >&2
                return 1
            end
            set -l target (__t_find $argv[2])
            or return 1

            set -l line (sed -n "$target"p $tasks_file)
            set -l updated

            switch $argv[3]
                case priority
                    # Priority is a (A) prefix at the start of the line
                    # Strip existing priority prefix if any
                    set updated (
                        string replace -r '^\([A-Z]\) ' '' -- $line
                    )
                    # Prepend new priority (empty value removes it)
                    if test -n "$argv[4]"
                        set updated "($argv[4]) $updated"
                    end
                case project
                    # Replace or add +project tag (todo.txt syntax)
                    set updated (string replace -r ' \+\S+' '' -- $line)
                    # Insert +tag before first key:value pair
                    if string match -qr ' \S+:\S+' -- $updated
                        set updated (
                            string replace -r ' (\S+:\S+)' \
                                " +$argv[4] \$1" -- $updated
                        )
                    else
                        set updated "$updated +$argv[4]"
                    end
                case dir
                    set -l value (string replace -- $HOME '~' $argv[4])
                    set updated (__t_set_field "$line" dir $value)
                case '*'
                    set updated (__t_set_field "$line" $argv[3] $argv[4])
            end

            __t_replace_line $target $updated
            echo "Updated: $updated"

            # -- edit ---------------------------------------------------
        case edit
            if test -n "$EDITOR"
                $EDITOR $tasks_file
            else
                nvim $tasks_file
            end

            # -- rm -----------------------------------------------------
        case rm remove
            if not set -q argv[2]
                echo "Usage: t rm <identifier>" >&2
                return 1
            end
            set -l target (__t_find --all $argv[2])
            or return 1

            set -l line (sed -n "$target"p $tasks_file)
            __t_remove_line $target
            echo "Removed: $line"

            # -- help ---------------------------------------------------
        case help
            echo "t -- task registry"
            echo ""
            echo "Subcommands:"
            echo "  t                     Interactive picker (default)"
            echo "  t add \"summary\" [flags]"
            echo "    --ticket, -t KEY    Linear ticket (auto-fetches title)"
            echo "    --dir PATH          Working directory"
            echo "    --session, -s ID    Agent session ID"
            echo "    --priority, -p X    Priority A-Z"
            echo "    --project NAME      Project (+tag; auto-detects from git)"
            echo "    --status STATUS     Initial status (default: active)"
            echo "  t list [--all] [--project X] [--status X]"
            echo "  t done <id>           Mark task done"
            echo "  t status <id> <s>     Set status (active/paused/blocked)"
            echo "  t session <id> <sid>  Set session ID"
            echo "  t set <id> <key> <val>  Set any key:value field"
            echo "  t edit                Open todo.txt in \$EDITOR"
            echo "  t rm <id>             Remove a task"
            echo ""
            echo "Pick keybindings:"
            echo "  enter     Resume agent session"
            echo "  ctrl-e    Edit todo.txt"
            echo "  ctrl-d    cd to task directory"
            echo "  ctrl-o    Open ticket in browser"
            echo "  ctrl-x    Mark done"
            echo ""
            echo "Data: ~/.tasks/todo.txt"

        case '*'
            echo "Unknown: $argv[1]. Run 't help'." >&2
            return 1
    end
end
