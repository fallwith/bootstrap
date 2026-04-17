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
        t set $ticket session $ticket 2>/dev/null
        claude --resume $ticket
    else
        cd ~/git/web
        or begin
            echo "Could not cd to ~/git/web"
            return 1
        end
        worktree $branch_name $base_branch
        or return 1
        set -l dir_tilde (string replace -- $HOME '~' $worktree_dir)
        t add "(A) $task_title +brightwheel/web ticket:$ticket session:$ticket dir:$dir_tilde"
        linear-cli issues start $ticket 2>/dev/null
        claude --name $ticket --permission-mode plan \
            "Fetch Linear ticket $ticket via linear-cli. Run these three commands: \
(1) linear-cli i get $ticket -o json \
(2) linear-cli comments list $ticket -o json \
Review the title, description, and comments, then propose an implementation plan before writing any code."
    end
end
