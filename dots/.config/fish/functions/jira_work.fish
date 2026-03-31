function jira_work -d 'Prep a new worktree and interactive Claude Code session for a Jira ticket'
    set -l ticket $argv[1]
    if not set -q ticket[1]
        echo "Usage: jira_work <Jira ticket number> [base branch]"
        return 1
    end

    set -l base_branch staging
    if set -q argv[2]
        set base_branch $argv[2]
    end

    # Fetch ticket summary via acli
    set -l summary (
      acli jira workitem view $ticket --fields summary --json 2>/dev/null \
        | jq -r '.fields.summary // empty'
    )

    set -l branch_name
    if test -n "$summary"
        set -l slug (
          string lower -- $summary \
            | string replace -ar '[^a-z0-9]+' '_' \
            | string trim -c '_' \
            | string sub -l 60
        )
        set branch_name "$ticket-$slug"
        echo "Ticket: $summary"
    else
        echo "Could not fetch ticket summary via acli."
        echo "Enter a short branch description (spaces become underscores):"
        read -P "> " -l desc
        if test -z "$desc"
            echo "Aborting."
            return 1
        end
        set branch_name "$ticket-"(
          string lower -- $desc \
            | string replace -ar '[^a-z0-9]+' '_' \
            | string trim -c '_'
        )
    end

    set -l worktree_dir ~/git/web/$branch_name
    if test -d $worktree_dir
        echo "Resuming work on $ticket in existing worktree"
        cd $worktree_dir
        claude --resume $ticket
    else
        cd ~/git/web
        or begin
            echo "Could not cd to ~/git/web"
            return 1
        end
        worktree $branch_name $base_branch
        or return 1
        claude --name $ticket --permission-mode plan \
            "Fetch Jira ticket $ticket via acli and review its details. \
Propose an implementation plan before writing any code."
    end
end
