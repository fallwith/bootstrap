function jira_create -d 'Create a Jira ticket via acli and print the new key'
    # ── Config ──────────────────────────────────────────────────
    set -l config_path ~/.config/jira_create.conf
    if not test -f $config_path
        echo "No config found at $config_path"
        echo "Creating one now -- fill in your project defaults."
        echo ""
        read -P "Jira project key (e.g. PROJ): " -l cfg_project
        read -P "Your email or account ID (or @me): " -l cfg_assignee
        read -P "Default issue type (e.g. Task): " -l cfg_type
        read -P "Status for active work (e.g. In Progress): " -l cfg_active
        read -P "Status for backlog (e.g. To Do): " -l cfg_backlog

        if test -z "$cfg_project" -o -z "$cfg_type"
            echo "Project and type are required. Aborting."
            return 1
        end

        printf '%s\n' \
            "project=$cfg_project" \
            "assignee=$cfg_assignee" \
            "default_type=$cfg_type" \
            "status_active=$cfg_active" \
            "status_backlog=$cfg_backlog" >$config_path
        echo ""
        echo "Config written to $config_path"
    end

    # Read config values
    set -l cfg_project
    set -l cfg_assignee
    set -l cfg_default_type
    set -l cfg_status_active
    set -l cfg_status_backlog

    while read -l line
        switch $line
            case '#*' ''
                continue
            case 'project=*'
                set cfg_project (string replace 'project=' '' -- $line)
            case 'assignee=*'
                set cfg_assignee (string replace 'assignee=' '' -- $line)
            case 'default_type=*'
                set cfg_default_type (string replace 'default_type=' '' -- $line)
            case 'status_active=*'
                set cfg_status_active (string replace 'status_active=' '' -- $line)
            case 'status_backlog=*'
                set cfg_status_backlog (string replace 'status_backlog=' '' -- $line)
        end
    end <$config_path

    # ── Args ────────────────────────────────────────────────────
    set -l summary
    set -l description
    set -l issue_type $cfg_default_type
    set -l parent
    set -l backlog 0
    set -l unassigned 0

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -d --description
                set i (math $i + 1)
                set description $argv[$i]
            case -t --type
                set i (math $i + 1)
                set issue_type $argv[$i]
            case -p --parent
                set i (math $i + 1)
                set parent $argv[$i]
            case --backlog
                set backlog 1
            case --unassigned
                set unassigned 1
            case '-*'
                echo "Unknown flag: $argv[$i]" >&2
                return 1
            case '*'
                if test -z "$summary"
                    set summary $argv[$i]
                else
                    echo "Unexpected argument: $argv[$i]" >&2
                    return 1
                end
        end
        set i (math $i + 1)
    end

    # ── Interactive fallbacks ───────────────────────────────────
    if test -z "$summary"
        read -P "Summary: " summary
        if test -z "$summary"
            echo "Summary is required. Aborting." >&2
            return 1
        end
    end

    if test -z "$description"
        read -P "Description (enter for none): " description
    end

    # ── Build command ───────────────────────────────────────────
    set -l cmd acli jira workitem create \
        --project $cfg_project \
        --type $issue_type \
        --summary $summary

    if test $unassigned -eq 0 -a -n "$cfg_assignee"
        set -a cmd --assignee $cfg_assignee
    end

    if test -n "$description"
        set -a cmd --description $description
    end

    if test -n "$parent"
        set -a cmd --parent $parent
    end

    # ── Create ──────────────────────────────────────────────────
    set -l result ($cmd 2>/dev/null)
    if test $status -ne 0
        echo "acli create failed." >&2
        echo $result >&2
        return 1
    end

    # acli may return JSON or a human-readable success message.
    # Try JSON first, fall back to parsing "Work item KEY-123 created".
    set -l ticket_key (echo $result | jq -r '.key // empty' 2>/dev/null)
    if test -z "$ticket_key"
        set ticket_key (string match -r '[A-Z]+-\d+' -- $result)
    end
    if test -z "$ticket_key"
        echo "Could not parse ticket key from response." >&2
        echo $result >&2
        return 1
    end

    # ── Transition ──────────────────────────────────────────────
    set -l target_status $cfg_status_active
    if test $backlog -eq 1
        set target_status $cfg_status_backlog
    end

    if test -n "$target_status"
        acli jira workitem transition \
            --key $ticket_key \
            --status $target_status \
            --yes 2>/dev/null
        or echo "Warning: could not transition $ticket_key to '$target_status'" >&2
    end

    # ── Output ──────────────────────────────────────────────────
    # Diagnostics to stderr so stdout is just the key (for piping)
    echo $result >&2
    if test -n "$target_status"
        echo "Status: $target_status" >&2
    end

    echo $ticket_key
end
