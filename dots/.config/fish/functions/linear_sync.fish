# linear_sync -- check Linear state for ticket: entries in todo.txt
# and offer to close any in a "closed" state.
#
# Closed states: Done, Canceled, Duplicate, Won't Do
#
# Workflow:
#   1. grep ticket:KEY from non-x-prefixed lines in ~/.tasks/todo.txt
#   2. linear-cli i get $key -o json | jq -r .state.name (per ticket)
#   3. show summary, prompt y/N to close all matched
#   4. on confirm: todo.sh do <line> for each, then t archive

function linear_sync -d 'Check Linear and close ticket: entries in done states'
    set -l tasks_file ~/.tasks/todo.txt
    set -l closed_states Done Canceled Duplicate "Won't Do"

    # Collect (lineno|ticket) for every non-x-prefixed line with a
    # discoverable Linear ticket key.
    #   1) ticket: field   2) first [A-Z]+-\d+ in line
    set -l candidates
    set -l lineno 0
    while read -l line
        set lineno (math $lineno + 1)
        string match -q 'x *' -- $line; and continue
        set -l ticket
        set -l m (string match -r 'ticket:(\S+)' -- $line)
        test (count $m) -ge 2; and set ticket $m[2]
        if test -z "$ticket"
            set m (string match -r '\b[A-Z]+-\d+\b' -- $line)
            test (count $m) -ge 1; and set ticket $m[1]
        end
        test -n "$ticket"; and set -a candidates "$lineno|$ticket"
    end <$tasks_file

    if test (count $candidates) -eq 0
        echo "No active ticket: entries to check."
        return 0
    end

    set -l c_ticket (printf '\e[38;2;157;214;231m')
    set -l c_close (printf '\e[38;2;254;126;170m')
    set -l c_dim (printf '\e[38;2;120;120;120m')
    set -l reset (printf '\e[0m')

    echo "Checking "(count $candidates)" tickets..."
    echo

    set -l done_lns
    for c in $candidates
        set -l parts (string split '|' -- $c)
        set -l ln $parts[1]
        set -l ticket $parts[2]

        set -l state (
            linear-cli i get $ticket -o json 2>/dev/null \
                | jq -r '.state.name // empty'
        )
        set -l padded (string pad -r -w 10 -- $ticket)

        if test -z "$state"
            printf '  %s%s%s  %s?  (failed to fetch)%s\n' \
                "$c_ticket" "$padded" "$reset" \
                "$c_dim" "$reset"
            continue
        end

        if contains -- $state $closed_states
            printf '  %s%s%s  %s%s%s  (will close)\n' \
                "$c_ticket" "$padded" "$reset" \
                "$c_close" "$state" "$reset"
            set -a done_lns $ln
        else
            printf '  %s%s%s  %s%s%s\n' \
                "$c_ticket" "$padded" "$reset" \
                "$c_dim" "$state" "$reset"
        end
    end

    if test (count $done_lns) -eq 0
        echo
        echo "Nothing to close."
        return 0
    end

    echo
    read -l -P "Close "(count $done_lns)" tasks? [y/N] " confirm
    if test "$confirm" != y -a "$confirm" != Y
        echo "Aborted."
        return 0
    end

    for ln in $done_lns
        todo.sh do $ln >/dev/null
    end
    echo "Marked "(count $done_lns)" done. Archiving..."
    t archive
end
