function linear_create -d 'Create a Linear issue via linear-cli and print the identifier'
    # Usage:
    #   linear_create [title] [options]
    #
    # Options:
    #   -d, --description TEXT  Issue description (markdown)
    #   -p, --priority NUM      Priority (1=urgent, 2=high, 3=normal, 4=low)
    #   -l, --label LABEL       Label name or uuid (can be specified
    #                           multiple times). Names are resolved to
    #                           team-scoped uuids via GraphQL; workspace
    #                           labels (e.g. "Bug") are the fallback when
    #                           no team match exists. Requires
    #                           LINEAR_API_KEY in the environment.
    #   -s, --state STATE       Override state (e.g. "In Progress", "Backlog")
    #   -a, --attach PATH       Attach a file (can be specified multiple times)
    #   --project NAME_OR_ID    Associate ticket with a Linear project
    #   --team TEAM_KEY         Override the configured team (for
    #                           cross-team handoff tickets). When set,
    #                           labels are resolved against this team.
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
    #   linear_create "Bug" -a screenshot.png -a logs.txt
    #   linear_create "Story" --project "Q3 Roadmap"
    #   linear_create "Handoff" --team FOX --unassigned -s Triage

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
    set -l attachments
    set -l project
    set -l team_override
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
            case -a --attach
                set i (math $i + 1)
                set -a attachments $argv[$i]
            case --project
                set i (math $i + 1)
                set project $argv[$i]
            case --team
                set i (math $i + 1)
                set team_override $argv[$i]
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

    # -- Apply team override ----------------------------------------
    # An explicit --team replaces the configured default for the rest
    # of the function, including label resolution.
    if test -n "$team_override"
        set cfg_team $team_override
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

    # Validate attachments exist before creating the ticket so we fail fast.
    for path in $attachments
        if not test -f "$path"
            echo "Attachment not found: $path" >&2
            return 1
        end
    end

    # -- Resolve label names to uuids -------------------------------
    # linear-cli matches label names case-insensitively across the
    # whole workspace and can pick the wrong team's label, which the
    # API then rejects. Resolve each name to an id ourselves,
    # preferring a team-scoped match before falling back to a
    # workspace-level label (e.g. "Bug" lives at the workspace level).
    set -l label_ids
    for lbl in $labels
        # UUID pass-through.
        if string match -qr '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -- $lbl
            set -a label_ids $lbl
            continue
        end

        if test -z "$LINEAR_API_KEY"
            echo "LINEAR_API_KEY not set; cannot resolve label '$lbl'." >&2
            return 1
        end

        set -l body (jq -nc --arg name "$lbl" '{
            query: "query L($name: String!) { issueLabels(filter: {name: {eq: $name}}) { nodes { id team { key name } } } }",
            variables: {name: $name}
        }')
        set -l response (curl -sS -X POST https://api.linear.app/graphql \
            -H "Authorization: $LINEAR_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$body")
        if test $status -ne 0
            echo "GraphQL request failed while resolving label '$lbl'." >&2
            return 1
        end

        set -l team_id (echo $response | jq -r --arg t "$cfg_team" \
            '[.data.issueLabels.nodes[]? | select(.team.key == $t or .team.name == $t)][0].id // empty')
        if test -n "$team_id"
            set -a label_ids $team_id
            continue
        end

        set -l workspace_id (echo $response | jq -r \
            '[.data.issueLabels.nodes[]? | select(.team == null)][0].id // empty')
        if test -n "$workspace_id"
            set -a label_ids $workspace_id
            continue
        end

        echo "No label named '$lbl' found for team '$cfg_team' or at workspace level." >&2
        return 1
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

    for lbl in $label_ids
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

    # -- Project association ----------------------------------------
    # Failures here don't fail the function -- the ticket already exists.
    if test -n "$project"
        if linear-cli issues update $ticket_id --project $project >/dev/null 2>&1
            echo "Project: $project" >&2
        else
            echo "Warning: failed to associate $ticket_id with project '$project'." >&2
        end
    end

    # -- Attachments ------------------------------------------------
    # Failures here don't fail the function -- the ticket already exists.
    if test (count $attachments) -gt 0
        echo "Attaching "(count $attachments)" file(s)..." >&2
        if not linear_attach $ticket_id $attachments >&2
            echo "Warning: linear_attach failed; ticket $ticket_id was created but attachments may be missing." >&2
        end
    end

    echo $ticket_id
end
