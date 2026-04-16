function linear_create -d 'Create a Linear issue via linear-cli and print the identifier'
    # Usage:
    #   linear_create [title] [options]
    #
    # Options:
    #   -d, --description TEXT  Issue description (markdown)
    #   -p, --priority NUM      Priority (1=urgent, 2=high, 3=normal, 4=low)
    #   -l, --label LABEL       Label (can be specified multiple times)
    #   -s, --state STATE       Override state (e.g. "In Progress", "Backlog")
    #   --backlog               Use backlog state instead of active
    #   --unassigned            Do not assign to self
    #
    # Omitted args are prompted for interactively.
    # Stdout is the ticket identifier only, for piping:
    #   linear_work (linear_create "Fix the widget")
    #
    # Config: ~/.config/linear_create.conf (created on first run)
    #
    # Examples:
    #   linear_create
    #   linear_create "Fix the widget"
    #   linear_create "Fix the widget" -d "Details here" -p 2
    #   linear_create "Backlog item" --backlog --unassigned
    #   linear_create "Bug" -l Bug -p 2

    # -- Config -----------------------------------------------------
    set -l config_path ~/.config/linear_create.conf
    if not test -f $config_path
        echo "No config found at $config_path"
        echo "Creating one now -- fill in your Linear defaults."
        echo ""
        read -P "Team key (e.g. ACT): " -l cfg_team
        read -P "Assignee (email, name, or 'me'): " -l cfg_assignee
        read -P "State for active work (e.g. In Progress): " -l cfg_active
        read -P "State for backlog (e.g. Backlog): " -l cfg_backlog

        if test -z "$cfg_team"
            echo "Team is required. Aborting."
            return 1
        end

        printf '%s\n' \
            "team=$cfg_team" \
            "assignee=$cfg_assignee" \
            "state_active=$cfg_active" \
            "state_backlog=$cfg_backlog" >$config_path
        echo ""
        echo "Config written to $config_path"
    end

    # Read config values
    set -l cfg_team
    set -l cfg_assignee
    set -l cfg_state_active
    set -l cfg_state_backlog

    while read -l line
        switch $line
            case '#*' ''
                continue
            case 'team=*'
                set cfg_team (string replace 'team=' '' -- $line)
            case 'assignee=*'
                set cfg_assignee (string replace 'assignee=' '' -- $line)
            case 'state_active=*'
                set cfg_state_active (string replace 'state_active=' '' -- $line)
            case 'state_backlog=*'
                set cfg_state_backlog (string replace 'state_backlog=' '' -- $line)
        end
    end <$config_path

    # -- Args -------------------------------------------------------
    set -l title
    set -l description
    set -l priority
    set -l labels
    set -l state_override
    set -l backlog 0
    set -l unassigned 0

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -d --description
                set i (math $i + 1)
                set description $argv[$i]
            case -p --priority
                set i (math $i + 1)
                set priority $argv[$i]
            case -l --label
                set i (math $i + 1)
                set -a labels $argv[$i]
            case -s --state
                set i (math $i + 1)
                set state_override $argv[$i]
            case --backlog
                set backlog 1
            case --unassigned
                set unassigned 1
            case '-*'
                echo "Unknown flag: $argv[$i]" >&2
                return 1
            case '*'
                if test -z "$title"
                    set title $argv[$i]
                else
                    echo "Unexpected argument: $argv[$i]" >&2
                    return 1
                end
        end
        set i (math $i + 1)
    end

    # -- Interactive fallbacks --------------------------------------
    if test -z "$title"
        read -P "Title: " title
        if test -z "$title"
            echo "Title is required. Aborting." >&2
            return 1
        end
    end

    if test -z "$description"
        read -P "Description (enter for none): " description
    end

    # -- Build command ----------------------------------------------
    set -l cmd linear-cli issues create $title \
        -t $cfg_team

    if test $unassigned -eq 0 -a -n "$cfg_assignee"
        set -a cmd -a $cfg_assignee
    end

    # Determine state
    set -l target_state
    if test -n "$state_override"
        set target_state $state_override
    else if test $backlog -eq 1 -a -n "$cfg_state_backlog"
        set target_state $cfg_state_backlog
    else if test -n "$cfg_state_active"
        set target_state $cfg_state_active
    end

    if test -n "$target_state"
        set -a cmd -s $target_state
    end

    if test -n "$description"
        set -a cmd -d $description
    end

    if test -n "$priority"
        set -a cmd -p $priority
    end

    for lbl in $labels
        set -a cmd -l $lbl
    end

    set -a cmd -o json -q

    # -- Create -----------------------------------------------------
    set -l result ($cmd 2>/dev/null)
    if test $status -ne 0
        echo "linear-cli create failed." >&2
        echo $result >&2
        return 1
    end

    set -l ticket_id (echo $result | jq -r '.identifier // empty' 2>/dev/null)
    if test -z "$ticket_id"
        echo "Could not parse identifier from response." >&2
        echo $result >&2
        return 1
    end

    # -- Output -----------------------------------------------------
    # Diagnostics to stderr so stdout is just the identifier (for piping)
    set -l ticket_title (echo $result | jq -r '.title // empty' 2>/dev/null)
    echo "Created: $ticket_id $ticket_title" >&2
    if test -n "$target_state"
        echo "State: $target_state" >&2
    end

    echo $ticket_id
end
