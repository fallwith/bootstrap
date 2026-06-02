function linear_ready -d 'List unblocked vs blocked issues for a Linear project (by name or id)'
    # Usage:
    #   linear_ready <project name or id>
    #
    # Prints two groups for the project's issues:
    #   READY NOW  -- not done/canceled and every "blocks" blocker is done
    #   BLOCKED    -- not done/canceled but waiting on incomplete blockers
    #
    # Arg resolution: a UUID is used directly; anything else is matched
    # against project names (case-insensitive contains). Multiple matches
    # abort with the candidate ids so you can re-run unambiguously.
    #
    # Requires LINEAR_API_KEY. Reads up to 50 issues per project.

    set -l arg $argv[1]
    if test -z "$arg"
        echo "Usage: linear_ready <project name or id>" >&2
        return 1
    end
    if test -z "$LINEAR_API_KEY"
        echo "LINEAR_API_KEY not set; cannot query Linear." >&2
        return 1
    end

    set -l api https://api.linear.app/graphql

    # -- Resolve project id -----------------------------------------
    set -l pid
    if string match -qr '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -- $arg
        set pid $arg
    else
        set -l body (jq -nc --arg q "$arg" '{query:"query($q:String!){projects(filter:{name:{containsIgnoreCase:$q}}){nodes{id name}}}",variables:{q:$q}}')
        set -l resp (curl -sS -X POST $api -H "Authorization: $LINEAR_API_KEY" -H "Content-Type: application/json" -d $body | string collect)
        set -l count (echo $resp | jq '.data.projects.nodes | length')
        if test "$count" = 0
            echo "No project matching '$arg'." >&2
            return 1
        else if test "$count" -gt 1
            echo "Multiple projects match '$arg' -- re-run with an id:" >&2
            echo $resp | jq -r '.data.projects.nodes[] | "  \(.name)  [\(.id)]"' >&2
            return 1
        end
        set pid (echo $resp | jq -r '.data.projects.nodes[0].id')
        echo "Project: "(echo $resp | jq -r '.data.projects.nodes[0].name')" [$pid]" >&2
    end

    # -- Fetch issues + blocked-by relations ------------------------
    set -l body (jq -nc --arg pid "$pid" '{query:"query($pid:String!){project(id:$pid){issues(first:50){nodes{identifier title state{type} inverseRelations{nodes{type issue{identifier}}}}}}}",variables:{pid:$pid}}')
    set -l iresp (curl -sS -X POST $api -H "Authorization: $LINEAR_API_KEY" -H "Content-Type: application/json" -d $body | string collect)

    if test (echo $iresp | jq -r 'if .data.project == null then "null" else "ok" end') = null
        echo "Project id '$pid' not found or not accessible." >&2
        return 1
    end
    if test (echo $iresp | jq '.data.project.issues.nodes | length') = 50
        echo "(note: 50 issues fetched; project may have more -- pagination not implemented)" >&2
    end

    set -l prog '.data.project.issues.nodes as $n | ($n | map({(.identifier): .state.type}) | add) as $st | ($n | map(. + {blockers: [.inverseRelations.nodes[]? | select(.type=="blocks") | .issue.identifier]})) | map(. + {incomplete: [.blockers[] | select($st[.] != "completed")]}) | sort_by(.identifier) | (map(select((.state.type|test("completed|canceled")|not) and (.incomplete|length==0)))) as $ready | (map(select((.state.type|test("completed|canceled")|not) and (.incomplete|length>0)))) as $blocked | "READY NOW (\($ready|length)):", ($ready[] | "  \(.identifier)  \(.title[0:50])"), "", "BLOCKED (\($blocked|length)):", ($blocked[] | "  \(.identifier)  <- \(.incomplete|join(", "))")'

    echo $iresp | jq -r $prog
end
