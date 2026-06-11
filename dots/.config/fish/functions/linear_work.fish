function linear_work -d 'Prep a new worktree and interactive Claude Code session for a Linear ticket'
    set -l ticket $argv[1]
    if not set -q ticket[1]
        echo "Usage: linear_work <ticket identifier> [base branch]"
        return 1
    end

    set -l base_branch staging
    if set -q argv[2]
        set base_branch $argv[2]
    end

    # Fetch ticket title via linear-cli
    set -l title (
        linear-cli i get $ticket -o json 2>/dev/null \
            | jq -r '.title // empty'
    )

    set -l branch_name
    if test -n "$title"
        set -l slug (
            string lower -- $title \
                | string replace -ar '[^a-z0-9]+' '_' \
                | string trim -c '_' \
                | string sub -l 60
        )
        set branch_name "$ticket-$slug"
        echo "Ticket: $title"
    else
        echo "Could not fetch ticket title via linear-cli."
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
    set -l task_title
    if test -n "$title"
        set task_title $title
    else
        set task_title $branch_name
    end

    if test -d $worktree_dir
        echo "Resuming work on $ticket in existing worktree"
        cd $worktree_dir
        # Look up tracked session UUID by ticket key in dir field
        set -l existing (
            grep -E "dir:[^ ]*$ticket-" ~/.tasks/todo.txt | head -1
        )
        set -l existing_uuid
        if test -n "$existing"
            set existing_uuid (
                string match -r 'session:(\S+)' -- $existing
            )[2]
        end
        if test -n "$existing_uuid"
            claude --resume $existing_uuid
        else
            echo "No tracked session for $ticket. Starting plain claude." >&2
            claude
        end
    else
        cd ~/git/web
        or begin
            echo "Could not cd to ~/git/web"
            return 1
        end
        worktree $branch_name $base_branch
        or return 1
        linear-cli i update $ticket -s 'In Progress' -a me -q
        or echo "Warning: failed to set $ticket to 'In Progress' or assign to self" >&2
        clod "$ticket $task_title" --permission-mode plan \
            "Fetch Linear ticket $ticket via linear-cli. Run these two commands: \
(1) linear-cli i get $ticket --comments -o json \
(2) linear-cli att list $ticket -o json \
Review the title, description, and comments. If any attachments are listed, \
download each into the worktree and review them -- read text files and view \
images via the Read tool. Then propose an implementation plan before writing \
any code. For any non-trivial task, ensure that the plan includes instructions \
to repeatedly make use of the '/simplify' command until it yields diminishing \
returns. Also, if the git repository involved offers a '/review-pr' command, \
ensure that the plan contains instructions to make use of it after the use of \
'/simplify'."
    end
end
