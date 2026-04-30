# clod -- start a tracked Claude Code session
#
# Generates a UUID, registers a task entry in ~/.tasks/todo.txt, and
# launches Claude Code with --name and --session-id pre-set.
#
# Bare `claude` invocations don't get tracked. Use `clod` when you
# want the session to show up in `t pick`.
#
# Usage:
#   clod "Fix the flux capacitor"
#
# linear_work calls clod with "TICKET title" so both are visible.

function clod -d 'Start a tracked Claude Code session'
    if not set -q argv[1]
        echo "Usage: clod <session name> [extra claude args...]" >&2
        return 1
    end
    if string match -q -- '-*' $argv[1]
        echo "clod: first arg must be the session name, not a flag." >&2
        echo "Usage: clod <session name> [extra claude args...]" >&2
        return 1
    end

    set -l name $argv[1]
    set -l rest $argv[2..]
    set -l session_id (uuidgen | string lower)
    set -l timestamp (date '+%Y-%m-%d %H:%M')
    set -l dir_tilde (string replace -- $HOME '~' (pwd))

    set -l line "$timestamp $name"

    set -l remote (git remote get-url origin 2>/dev/null)
    if test -n "$remote"
        set -l project (
            echo $remote \
                | string replace -r '.*[:/]([^/]+/[^/]+?)(\.git)?$' '$1'
        )
        set line "$line +$project"
    end

    set line "$line session:$session_id dir:$dir_tilde agent:claude"

    t add "$line"
    claude --name "$name" --session-id $session_id $rest
end
