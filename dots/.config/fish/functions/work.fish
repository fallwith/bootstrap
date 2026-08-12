# work -- project lifecycle for LLM agent sessions
#
# A project is a directory under ~/projects. Its name is either
# "TICKET-slug" (Linear-ticketed, e.g. ACT-123-fix_the_widget) or
# "PREFIX-slug" for untracked work (e.g. CHORE-clean_dotfiles).
# The directory IS the registry: a project exists iff its directory
# does. project.json in the project root records the ticket, repos
# (worktrees/clones), and agent sessions.
#
# Usage:
#   work                      fzf picker over projects (enter:resume,
#                               ctrl-d:cd, ctrl-o:ticket)
#   work list                 plain project listing
#   work <id> [options]       resume if it exists, else create
#   work .                    resume the project you're inside
#   work resume <pattern>     find a ~/projects session by transcript
#                               content and resume the matched session
#   work adopt                register the current directory as a
#                               project (detects repos, backfills
#                               Claude sessions recorded for it)
#   work promote <id> [opts]  run from an ad-hoc directory: create a
#                               new project (same options as create),
#                               re-home this dir's newest session
#                               transcript (-s for a specific one) to
#                               the project, and resume it there
#   work add <repo> [-b BASE] add a repo worktree to the current
#                               project when scope expands
#   work status               local status of every project: dirty,
#                               ahead/behind, age (no network calls)
#   work done [id] [--force]  tear a project down: remove worktrees
#                               and branches, write a complete archive
#                               (project.json, session transcripts,
#                               branch diffs/logs/bundles, stray files)
#                               to ~/projects/.archive/<name>.tar.gz
#                               alongside the bare .json, mark todo.txt
#                               entries done. Refuses dirty/unpushed
#                               repos unless --force.
#   work revive <id>          restore an archived project from its
#                               tarball: project dir, stray files,
#                               transcripts back into ~/.claude, and
#                               worktrees (branch from local/origin/
#                               bundle/start commit, first available)
#   work gc                   flag projects whose ticket is
#                               Done/Canceled, whose branch is merged
#                               or upstream-gone, or idle > 30 days;
#                               prompt to tear each down
#
# Create options:
#   -r/--repo NAME    repo to include (repeatable, required for
#                       ticketed/new multi-repo projects)
#   -b/--base BRANCH  base branch for new feature branches
#                       (default: repos.<name>.base in
#                        ~/.config/work/config.json, then the
#                        repo's origin/HEAD)
#   -n/--no-launch    prep the project but don't start a session
#   --no-claim        skip the Linear In Progress + assign-to-me
#                       transition (e.g. taking over a reopened
#                       ticket that isn't yours yet)
#   --no-intake       no intake prompt, ever, for this project --
#                       sessions start blank
#
# Repos resolve to durable clones at ~/git/<name> (bare-container
# or normal clone; a "source" path in config.json overrides).
# Feature branches are created as worktrees under the project
# directory with an explicit origin/<base> start-point. Sessions
# are launched directly (claude --session-id) and recorded in
# project.json; nothing is written to todo.txt.

function __work_config --description 'Read a value from ~/.config/work/config.json'
    set -l cfg ~/.config/work/config.json
    test -f $cfg; or return 1
    set -l val (jq -r "$argv[1] // empty" $cfg 2>/dev/null)
    test -n "$val"; or return 1
    printf '%s\n' $val
end

function __work_slug --description 'Lowercase, underscore, and truncate a title'
    string lower -- $argv[1] \
        | string replace -ar '[^a-z0-9]+' _ \
        | string trim -c _ \
        | string sub -l 60
end

function __work_find --description 'Locate an existing project directory'
    set -l id $argv[1]
    if test -d ~/projects/$id
        echo ~/projects/$id
        return 0
    end
    set -l matches ~/projects/$id-*/
    test (count $matches) -eq 0; and return 1
    if test (count $matches) -gt 1
        echo "Multiple projects match $id; using the first:" >&2
        printf '  %s\n' $matches >&2
    end
    string trim -r -c / -- $matches[1]
end

function __work_source --description 'Resolve a repo name to its durable git dir'
    set -l repo $argv[1]
    set -l configured (__work_config ".repos[\"$repo\"].source")
    if test -n "$configured"
        set configured (string replace -r '^~' $HOME -- $configured)
        if not test -d $configured
            echo "Configured source for $repo not found: $configured" >&2
            return 1
        end
        echo $configured
        return 0
    end
    test -d ~/git/$repo/.bare; and echo ~/git/$repo/.bare; and return 0
    test -e ~/git/$repo/.git; and echo ~/git/$repo; and return 0
    return 1
end

function __work_base --description 'Determine the base branch for a repo'
    set -l repo $argv[1]
    set -l src $argv[2]
    set -l configured (__work_config ".repos[\"$repo\"].base")
    if test -n "$configured"
        echo $configured
        return 0
    end
    set -l head (git -C $src symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
    if test -n "$head"
        string replace origin/ '' -- $head
        return 0
    end
    return 1
end

function __work_link_personal --description 'Symlink personal per-repo agent instructions into a checkout'
    set -l wt $argv[1]
    set -l repo $argv[2]
    set -l src $HOME/.agents/$repo-personal.md

    test -f $src; or return 0

    # One real file, one symlink per agent that needs its own name:
    # Claude Code discovers only CLAUDE.local.md, Codex only
    # AGENTS.override.md (which beats a committed AGENTS.md). Both
    # are gitignored via ~/.config/git/ignore. Linked per repo
    # rather than at the project root, since a multi-repo project
    # would otherwise apply one repo's rules to the others.
    for name in CLAUDE.local.md AGENTS.override.md
        test -e $wt/$name; or ln -s $src $wt/$name
    end
end

function __work_worktree_add --description 'Create a project worktree and emit its repo JSON'
    set -l projdir $argv[1]
    set -l repo $argv[2]
    set -l src $argv[3]
    set -l base $argv[4]
    set -l branch (basename $projdir)
    set -l wt $projdir/$repo

    echo "Preparing $repo: branch $branch from origin/$base" >&2
    git -C $src fetch origin $base >&2
    or echo "Warning: fetch of origin/$base failed; using local refs" >&2

    if git -C $src show-ref --verify --quiet refs/heads/$branch
        git -C $src worktree add $wt $branch >&2; or return 1
    else
        git -C $src worktree add $wt -b $branch origin/$base >&2; or return 1
    end

    __work_link_personal $wt $repo

    # The branch tip at creation time: `work gc` treats the branch as
    # merged only when the tip has moved AND is in the base, so a
    # fresh no-commits branch is never flagged.
    set -l start (git -C $src rev-parse refs/heads/$branch)

    jq -nc --arg name $repo --arg path $repo --arg mode worktree \
        --arg source (string replace -- $HOME '~' $src) \
        --arg branch $branch --arg base $base --arg start $start \
        '{name: $name, path: $path, mode: $mode, source: $source,
          branch: $branch, base: $base, start: $start}'
end

function __work_prompt --description 'Build the intake prompt for a ticketed project'
    set -l projdir $argv[1]
    set -l ticket $argv[2]
    set -l repos $argv[3..]

    set -l template ~/.config/work/intake.md
    test -n "$ticket" -a -f "$template"; or return 0

    set -l prompt (string replace -a '{{TICKET}}' $ticket <$template | string collect)
    for repo in $repos
        set -l overlay
        if test -f $projdir/$repo/.agents/work-intake.md
            set overlay $projdir/$repo/.agents/work-intake.md
        else if test -f ~/.config/work/overlays/$repo.md
            set overlay ~/.config/work/overlays/$repo.md
        end
        if test -n "$overlay"
            set prompt "$prompt

"(string collect <$overlay)
        end
    end
    printf '%s' $prompt
end

function __work_ruby_path --description 'Ruby bin dir when the project repos agree on one .ruby-version'
    set -l projdir $argv[1]
    set -l versions
    for path in (jq -r '.repos[]?.path' $projdir/project.json 2>/dev/null)
        set -l f $projdir/$path/.ruby-version
        test -f $f; or continue
        set -a versions (string trim <$f)
    end
    set -l distinct (printf '%s\n' $versions | sort -u | string match -rv '^$')
    test (count $distinct) -gt 0; or return 1
    if test (count $distinct) -gt 1
        echo "Note: conflicting .ruby-version across repos ("(string join ', ' $distinct)"); not pinning a session Ruby." >&2
        return 1
    end
    set -l bin $HOME/.rubies/ruby-$distinct[1]/bin
    if not test -d $bin
        echo "Warning: ruby-$distinct[1] not installed under ~/.rubies; not pinning." >&2
        return 1
    end
    echo $bin
end

function __work_claude --description 'Launch claude with the project Ruby first on PATH'
    set -l projdir $argv[1]
    set -l ruby_bin (__work_ruby_path $projdir)
    if test -n "$ruby_bin"
        # Env on the claude process reaches every Bash tool call in
        # the session, so bundle/rspec/rubocop resolve the pinned
        # Ruby without per-command PATH prefixes.
        env "PATH=$ruby_bin:"(string join : $PATH) claude $argv[2..]
    else
        claude $argv[2..]
    end
end

function __work_claude_session --description 'Launch a new Claude session recorded in project.json'
    set -l pf $argv[1]
    set -l rest $argv[2..]
    set -l session_id (uuidgen | string lower)
    set -l tmp (mktemp)
    jq --arg id $session_id \
        --arg started (date '+%Y-%m-%dT%H:%M') \
        --arg cwd (string replace -- $HOME '~' (pwd)) \
        '.sessions += [{agent: "claude", id: $id,
          started: $started, cwd: $cwd}]' \
        $pf >$tmp
    and command mv -f $tmp $pf
    # Named after the project dir: the session name drives the
    # terminal tab title (undocumented, no other knob), and the
    # leading ticket id is what makes tabs tellable-apart.
    set -l projdir (dirname $pf)
    __work_claude $projdir --name (basename $projdir) --session-id $session_id $rest
end

function __work_launch --description 'Start a tracked session for a project'
    set -l projdir $argv[1]
    set -l prompt $argv[2]
    set -l pf $projdir/project.json

    # Single-repo projects run from the repo so its slash commands
    # and CLAUDE.md are discovered; multi-repo runs from the root.
    set -l repo_paths (jq -r '.repos[]?.path' $pf)
    if test (count $repo_paths) -eq 1
        cd $projdir/$repo_paths[1]
    else
        cd $projdir
    end

    if test -n "$prompt"
        __work_claude_session $pf --permission-mode plan $prompt
    else
        __work_claude_session $pf
    end
end

function __work_resume --description 'Resume the latest session of an existing project'
    set -l projdir $argv[1]
    set -l pf $projdir/project.json
    if not test -f $pf
        echo "$projdir has no project.json." >&2
        echo "Run 'work adopt' from inside it to register." >&2
        cd $projdir
        return 1
    end

    # Newest session with a transcript claude can actually resume:
    # a session exited before its first prompt writes only metadata
    # lines, and `claude --resume` refuses those ("No conversation
    # found"). Retention-pruned transcripts are equally unresumable.
    set -l TAB (printf '\t')
    set -l sess ''
    set -l dir ''
    for row in (jq -r '.sessions | reverse | .[] | [.id, (.cwd // "")] | @tsv' $pf)
        set -l f (string split $TAB -- $row)
        set -l cwd (string replace -r '^~' $HOME -- $f[2])
        test -n "$cwd"; or set cwd $projdir
        set -l t ~/.claude/projects/(string replace -ar '[/._]' '-' -- $cwd)/$f[1].jsonl
        if test -f $t; and grep -qE '"type":"(user|assistant)"' $t
            set sess $f[1]
            set dir $cwd
            break
        end
    end

    if test -z "$sess"
        # Nothing resumable (never launched, exited unprompted, or
        # pruned): start fresh, with the intake prompt if ticketed
        # and the project wasn't created with --no-intake.
        if test (jq -r '.sessions | length' $pf) -gt 0
            echo "No resumable session transcript; starting a new session."
        end
        set -l prompt ''
        # NB: not `.intake // true` -- jq's // treats false as absent
        if test (jq -r '.intake != false' $pf) = true
            set -l ticket (jq -r '.ticket // empty' $pf)
            set -l repos (jq -r '.repos[]?.path' $pf)
            set prompt (__work_prompt $projdir "$ticket" $repos | string collect)
        end
        __work_launch $projdir "$prompt"
        return
    end

    test -d "$dir"; or set dir $projdir
    cd $dir
    __work_claude $projdir --resume $sess
end

function __work_first_prompt --description 'Extract a recognizable opening prompt from a session jsonl'
    set -l f $argv[1]
    test -r "$f"; or return 1
    # Pull user-typed string content with newlines/tabs flattened so
    # each logical message is one element when read by fish.
    set -l prompts (
        head -200 $f \
            | jq -r '
                select(.type=="user" and (.message.content | type) == "string")
                | .message.content | gsub("\n"; " ") | gsub("\t"; " ")
              ' 2>/dev/null
    )
    set -l slash ''
    set -l first ''
    for line in $prompts
        # Render slash-command invocations as "/cmd args" rather than
        # skipping them.
        if string match -q -r '<command-name>' -- $line
            if test -z "$slash"
                set -l name_match (string match -r '<command-name>([^<]+)</command-name>' -- $line)
                set -l args_match (string match -r '<command-args>([^<]+)</command-args>' -- $line)
                set slash $name_match[2]
                if test (count $args_match) -ge 2; and test -n "$args_match[2]"
                    set slash "$slash $args_match[2]"
                end
            end
            continue
        end
        # Skip other synthetic prompt wrappers.
        if string match -q -r '^(<command-(stdout|stderr|message)|<local-command|<system-reminder>|<bash-input|Caveat:)' -- $line
            continue
        end
        set first $line
        break
    end
    set -l out
    test -n "$slash"; and set -a out $slash
    test -n "$first"; and set -a out $first
    test (count $out) -eq 0; and return 0
    string sub -l 200 -- (string join ' | ' -- $out)
end

function __work_session_search --description 'Find a session by transcript content and resume it'
    set -l pattern $argv[1]
    if test -z "$pattern"
        echo "Usage: work resume <text pattern>" >&2
        return 1
    end
    for cmd in fzf jq
        if not command -q $cmd
            echo "work resume requires $cmd" >&2
            return 1
        end
    end
    set -l grep_cmd
    if command -q ug
        set grep_cmd ug -ilr
    else if command -q rg
        set grep_cmd rg -il
    else
        set grep_cmd grep -rli
    end

    set -l TAB (printf '\t')
    set -l rows
    # Transcripts stay where the agents keep them (~/.claude for now,
    # ~/.codex later); the cwd recorded in each jsonl maps a hit back
    # to its project. Only ~/projects sessions are offered: the dir
    # encoding is lossy, so pre-filter by encoded prefix for speed and
    # confirm against the recorded cwd for correctness.
    set -l enc_prefix (string replace -ar '[/._]' '-' -- $HOME/projects)
    set -l search_dirs ~/.claude/projects/$enc_prefix-*/
    if test (count $search_dirs) -eq 0
        echo "No project sessions recorded yet." >&2
        return 1
    end
    for f in ($grep_cmd $pattern $search_dirs 2>/dev/null | grep -v '/subagents/')
        string match -q '*.jsonl' -- $f; or continue
        set -l mtime (stat -f '%m' $f)
        set -l iso (date -r $mtime '+%Y-%m-%d %H:%M')
        set -l session (basename $f .jsonl)
        set -l cwd (head -50 $f | jq -r 'select(.cwd != null) | .cwd' 2>/dev/null | head -1)
        test -n "$cwd"; or continue
        string match -q "$HOME/projects/*" -- $cwd; or continue
        set -l proj (
            string replace -- "$HOME/projects/" '' $cwd \
                | string split -m1 /
        )[1]
        set -l prompt (__work_first_prompt $f)
        set -a rows "$mtime$TAB$iso$TAB$proj$TAB"claude"$TAB$session$TAB$cwd$TAB$prompt"
    end
    if test (count $rows) -eq 0
        echo "No project sessions matching '$pattern'." >&2
        return 1
    end

    set -l line (
        printf '%s\n' $rows | sort -rn \
            | fzf --delimiter=$TAB --with-nth=2,3,7 \
                --header='time / project / first prompt'
    )
    test -z "$line"; and return 1
    set -l parts (string split $TAB -- $line)
    set -l agent $parts[4]
    set -l session $parts[5]
    set -l cwd $parts[6]
    if not test -d "$cwd"
        echo "Session directory not found: $cwd" >&2
        return 1
    end
    cd $cwd
    switch $agent
        case claude
            set -l pfile (__work_project_file $cwd)
            if test -n "$pfile"
                __work_claude (dirname $pfile) --resume $session
            else
                claude --resume $session
            end
        case codex
            codex resume $session
    end
end

function __work_start --description 'Create a project, or resume it if it exists'
    argparse 'r/repo=+' 'b/base=' n/no-launch no-claim no-intake -- $argv
    or return 1

    set -l id $argv[1]
    if test -z "$id"
        echo "Usage: work <TICKET|PREFIX-slug> [-r repo]... [-b base] [-n] [--no-claim] [--no-intake]" >&2
        return 1
    end

    set -l existing (__work_find $id)
    if test -n "$existing"
        if set -q _flag_no_launch
            echo "Project already exists: $existing"
            cd $existing
            return 0
        end
        __work_resume $existing
        return
    end

    # --- New project: derive name and title ---
    set -l ticket ''
    set -l title ''
    set -l name
    if string match -qr '^[A-Z]+-\d+$' -- $id
        set ticket $id
        set title (
            linear-cli i get $ticket -o json 2>/dev/null \
                | jq -r '.title // empty'
        )
        if test -n "$title"
            echo "Ticket: $title"
        else
            echo "Could not fetch $ticket title via linear-cli."
            read -P "Short description (spaces become underscores): " -l desc
            if test -z "$desc"
                echo "Aborting." >&2
                return 1
            end
            set title $desc
        end
        set name "$ticket-"(__work_slug $title)
    else if string match -q '*-*' -- $id
        set name $id
        set title (
            string split -m1 -- '-' $id \
                | tail -1 \
                | string replace -a '_' ' '
        )
    else
        echo "Identifier must look like ACT-123 or CHORE-short_slug" >&2
        return 1
    end

    # Ticketed work must name its repo(s) explicitly; untracked
    # prefixes (CHORE-, ONCALL-, ...) may be repo-less scratch
    # projects that exist just to anchor findable sessions.
    set -l repos $_flag_repo
    if test -z "$repos"; and test -n "$ticket"
        echo "A ticketed project needs at least one --repo (e.g. --repo web)." >&2
        return 1
    end

    # Resolve every repo's source and base before touching disk.
    set -l srcs
    set -l bases
    for repo in $repos
        set -l src (__work_source $repo)
        if test -z "$src"
            echo "No local clone for $repo (looked in ~/git/$repo)." >&2
            echo "Clone it first, or add repos.$repo.source to ~/.config/work/config.json." >&2
            return 1
        end
        set -l base $_flag_base
        test -n "$base"; or set base (__work_base $repo $src)
        if test -z "$base"
            echo "Could not determine base branch for $repo; pass --base." >&2
            return 1
        end
        set -a srcs $src
        set -a bases $base
    end

    set -l projdir ~/projects/$name
    mkdir -p $projdir

    set -l repo_objs
    set -l created_paths
    set -l created_srcs
    set -l i 0
    for repo in $repos
        set i (math $i + 1)
        set -l obj (__work_worktree_add $projdir $repo $srcs[$i] $bases[$i])
        if test -z "$obj"
            echo "Worktree creation failed for $repo; rolling back." >&2
            set -l j 0
            for p in $created_paths
                set j (math $j + 1)
                git -C $created_srcs[$j] worktree remove --force $p 2>/dev/null
            end
            rm -rf $projdir
            return 1
        end
        set -a created_paths $projdir/$repo
        set -a created_srcs $srcs[$i]
        set -a repo_objs $obj
    end

    printf '%s\n' $repo_objs | jq -s \
        --arg ticket "$ticket" --arg title "$title" \
        --arg created (date '+%Y-%m-%dT%H:%M') \
        '{ticket: (if $ticket == "" then null else $ticket end),
          title: $title, created: $created, repos: ., sessions: []}' >$projdir/project.json

    if test -n "$ticket"; and not set -q _flag_no_claim
        # linear-cli can report success without applying (observed
        # 2026-08-06 on a ticket In Review + assigned to a coworker),
        # so verify against Linear rather than trusting the exit code.
        linear-cli i update $ticket -s 'In Progress' -a me -q >/dev/null 2>&1
        set -l verify (
            linear-cli i get $ticket -o json 2>/dev/null \
                | jq -r '(.state.name? // .state // "?") + " / "
                    + (.assignee.email? // .assignee.name?
                       // (if (.assignee | type) == "string" then .assignee
                           else "unassigned" end))'
        )
        if string match -q 'In Progress / *' -- "$verify"
            echo "Claimed $ticket ($verify)."
        else
            echo "WARNING: claim of $ticket did not stick (now: $verify)." >&2
            echo "Set it In Progress / assigned to you manually in Linear." >&2
        end
    end
    if set -q _flag_no_intake
        set -l tmp (mktemp)
        jq '.intake = false' $projdir/project.json >$tmp
        and command mv -f $tmp $projdir/project.json
    end

    # Project-root agent instructions (AGENTS.md is tool-neutral;
    # CLAUDE.md symlinks to it). Claude Code loads CLAUDE.md from
    # every ancestor of its cwd, so this reaches sessions launched
    # in repo subdirs too. The scratchpad redirect is instruction-
    # level (no harness knob exists for the /tmp scratchpad).
    mkdir -p $projdir/scratchpad
    begin
        echo "# $name"
        echo ""
        test -n "$title"; and echo "$title"
        test -n "$ticket"; and echo "Linear ticket: $ticket"
        echo ""
        echo "## Scratchpad convention"
        echo ""
        echo "Use `$projdir/scratchpad/` for ALL temporary files"
        echo "(scripts, intermediate data, working notes) instead of"
        echo "the harness-provided /tmp scratchpad or any other system"
        echo "temp directory. Files there survive across sessions and"
        echo "are archived with the project at teardown."
    end >$projdir/AGENTS.md
    ln -s AGENTS.md $projdir/CLAUDE.md

    echo "Created $projdir"
    if set -q _flag_no_launch
        cd $projdir
        return 0
    end
    __work_resume $projdir
end

function __work_promote --description 'Convert an ad-hoc session in the current dir into a project'
    argparse 'r/repo=+' 'b/base=' 's/session=' n/no-launch no-claim no-intake -- $argv
    or return 1
    set -l id $argv[1]
    if test -z "$id"
        echo "Usage: work promote <TICKET|PREFIX-slug> [-s session-id] [-r repo]... [-b base] [-n] [--no-claim] [--no-intake]" >&2
        return 1
    end
    set -l srcdir (pwd)
    if string match -q "$HOME/projects/*" -- $srcdir
        echo "Already inside ~/projects; run promote from the ad-hoc directory." >&2
        return 1
    end
    set -l existing (__work_find $id 2>/dev/null)
    if test -n "$existing"
        echo "Project already exists: $existing. Promote only creates new projects." >&2
        return 1
    end

    set -l srcenc ~/.claude/projects/(string replace -ar '[/._]' '-' -- $srcdir)
    set -l sid $_flag_session
    if test -z "$sid"
        set -l candidates $srcenc/*.jsonl
        if test (count $candidates) -eq 0
            echo "No Claude sessions recorded for $srcdir" >&2
            return 1
        end
        set sid (basename (ls -t $candidates | head -1) .jsonl)
    end
    if not test -f $srcenc/$sid.jsonl
        echo "No transcript for session $sid under $srcdir" >&2
        set -l elsewhere ~/.claude/projects/*/$sid.jsonl
        if test (count $elsewhere) -gt 0
            echo "It exists elsewhere:" >&2
            for f in $elsewhere
                set -l fcwd (head -50 $f | jq -r 'select(.cwd != null) | .cwd' 2>/dev/null | head -1)
                echo "  $f" >&2
                echo "    (recorded cwd: $fcwd)" >&2
            end
            echo "If an earlier promote of a since-deleted project moved it," >&2
            echo "mv it back into $srcenc/ and retry." >&2
        end
        return 1
    end
    echo "Promoting session $sid:"
    echo "  "(__work_first_prompt $srcenc/$sid.jsonl)

    set -l create_args $id --no-launch
    for r in $_flag_repo
        set -a create_args --repo $r
    end
    test -n "$_flag_base"; and set -a create_args --base $_flag_base
    set -q _flag_no_claim; and set -a create_args --no-claim
    set -q _flag_no_intake; and set -a create_args --no-intake
    __work_start $create_args
    or return 1

    set -l projdir (__work_find $id)
    set -l pf $projdir/project.json

    # Session cwd follows the launch convention: single-repo projects
    # live in the repo subdir, otherwise the project root.
    set -l repo_paths (jq -r '.repos[]?.path' $pf)
    set -l newcwd $projdir
    test (count $repo_paths) -eq 1; and set newcwd $projdir/$repo_paths[1]

    # Re-home the transcript so resume finds it at the new cwd.
    set -l newenc ~/.claude/projects/(string replace -ar '[/._]' '-' -- $newcwd)
    mkdir -p $newenc
    command mv $srcenc/$sid.jsonl $newenc/
    test -d $srcenc/$sid; and command mv $srcenc/$sid $newenc/

    set -l mtime (stat -f '%m' $newenc/$sid.jsonl)
    set -l tmp (mktemp)
    jq --arg id $sid \
        --arg started (date -r $mtime '+%Y-%m-%dT%H:%M') \
        --arg cwd (string replace -- $HOME '~' $newcwd) \
        '.sessions += [{agent: "claude", id: $id,
          started: $started, cwd: $cwd}]' \
        $pf >$tmp
    and command mv -f $tmp $pf

    if test (count (git -C $srcdir status --porcelain 2>/dev/null)) -gt 0
        echo "Note: $srcdir has uncommitted changes. To carry them over:"
        echo "  git -C $srcdir diff >/tmp/promote.patch"
        echo "  git -C $newcwd apply /tmp/promote.patch"
    end
    echo "Promoted session $sid into "(basename $projdir)"."
    echo "Its earlier context references $srcdir -- tell Claude the work now lives in $newcwd."

    if set -q _flag_no_launch
        cd $projdir
        return 0
    end
    cd $newcwd
    __work_claude $projdir --resume $sid
end

function __work_add --description 'Add a repo worktree to an existing project'
    argparse 'b/base=' -- $argv
    or return 1
    set -l repo $argv[1]
    if test -z "$repo"
        echo "Usage: work add <repo> [--base BRANCH] (run inside a project)" >&2
        return 1
    end
    set -l pfile (__work_project_file (pwd))
    if test -z "$pfile"
        echo "Not inside a ~/projects project." >&2
        return 1
    end
    set -l projdir (dirname $pfile)
    set -l name (basename $projdir)

    if jq -e --arg name $repo 'any(.repos[]?; .name == $name)' $pfile >/dev/null
        echo "$repo is already part of $name." >&2
        return 1
    end
    if test -e $projdir/$repo
        echo "$projdir/$repo already exists on disk; work adopt instead?" >&2
        return 1
    end

    set -l src (__work_source $repo)
    if test -z "$src"
        echo "No local clone for $repo (looked in ~/git/$repo)." >&2
        echo "Clone it first, or add repos.$repo.source to ~/.config/work/config.json." >&2
        return 1
    end
    set -l base $_flag_base
    test -n "$base"; or set base (__work_base $repo $src)
    if test -z "$base"
        echo "Could not determine base branch for $repo; pass --base." >&2
        return 1
    end

    set -l obj (__work_worktree_add $projdir $repo $src $base)
    test -n "$obj"; or return 1

    set -l tmp (mktemp)
    jq --argjson repo "$obj" '.repos += [$repo]' $pfile >$tmp
    and command mv -f $tmp $pfile
    echo "Added $repo to $name."
end

function __work_adopt --description 'Register the current directory as a project'
    set -l here (pwd)
    if not string match -q "$HOME/projects/*" -- $here
        echo "work adopt must be run from inside ~/projects/<name>" >&2
        return 1
    end
    set -l name (
        string replace -- "$HOME/projects/" '' $here \
            | string split -m1 /
    )[1]
    set -l projdir $HOME/projects/$name
    set -l pf $projdir/project.json

    set -l ticket ''
    set -l m (string match -r '^([A-Z]+-\d+)-' -- $name)
    test (count $m) -ge 2; and set ticket $m[2]

    if not test -f $pf
        set -l title ''
        if test -n "$ticket"
            set title (
                linear-cli i get $ticket -o json 2>/dev/null \
                    | jq -r '.title // empty'
            )
        end
        if test -z "$title"
            set title (
                string replace -r '^[A-Za-z]+-(\d+-)?' '' -- $name \
                    | string replace -a '_' ' '
            )
        end
        jq -n --arg ticket "$ticket" --arg title "$title" \
            --arg created (date '+%Y-%m-%dT%H:%M') \
            '{ticket: (if $ticket == "" then null else $ticket end),
              title: $title, created: $created, repos: [], sessions: []}' >$pf
        echo "Created $pf"
    end

    # Detect repos: first-level children that are git checkouts.
    for child in $projdir/*/
        set -l dir (string trim -r -c / -- $child)
        test -e $dir/.git; or continue
        set -l repo (basename $dir)
        set -l branch (git -C $dir branch --show-current 2>/dev/null)
        set -l mode clone
        set -l source ''
        if test -f $dir/.git
            set mode worktree
            set source (git -C $dir rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
            # Normal clones report <clone>/.git as the common dir;
            # record the clone dir itself (matches __work_source).
            if test (basename "$source") = .git
                set source (dirname $source)
            end
            set source (string replace -- $HOME '~' $source)
        end
        set -l tmp (mktemp)
        jq --arg name $repo --arg path $repo --arg mode $mode \
            --arg source "$source" --arg branch "$branch" \
            'if any(.repos[]?; .name == $name) then . else
               .repos += [{name: $name, path: $path, mode: $mode,
                 source: (if $source == "" then null else $source end),
                 branch: (if $branch == "" then null else $branch end),
                 base: null}] end' $pf >$tmp
        and command mv -f $tmp $pf
        __work_link_personal $dir $repo
    end

    # Backfill Claude sessions recorded for the project root and each
    # repo subdir (Claude Code keys session history by cwd, encoding
    # the path with '/', '.', and '_' all mapped to '-').
    set -l scan_dirs $projdir
    for p in (jq -r '.repos[]?.path' $pf)
        set -a scan_dirs $projdir/$p
    end
    set -l TAB (printf '\t')
    set -l entries
    for d in $scan_dirs
        set -l enc (string replace -ar '[/._]' '-' -- $d)
        for f in ~/.claude/projects/$enc/*.jsonl
            set -l id (basename $f .jsonl)
            set -l mtime (stat -f '%m' $f)
            set -l started (date -r $mtime '+%Y-%m-%dT%H:%M')
            set -l cwd (string replace -- $HOME '~' $d)
            set -a entries "$mtime$TAB$id$TAB$started$TAB$cwd"
        end
    end
    for entry in (printf '%s\n' $entries | sort -n)
        test -n "$entry"; or continue
        set -l parts (string split $TAB -- $entry)
        set -l tmp (mktemp)
        jq --arg id $parts[2] --arg started $parts[3] --arg cwd $parts[4] \
            'if any(.sessions[]?; .id == $id) then . else
               .sessions += [{agent: "claude", id: $id,
                 started: $started, cwd: $cwd}] end' $pf >$tmp
        and command mv -f $tmp $pf
    end

    echo "Adopted $name: "(
        jq -r '"\(.repos | length) repos, \(.sessions | length) sessions"' $pf
    )
end

function __work_activity --description 'Epoch of the latest activity in a project'
    set -l projdir $argv[1]
    set -l pf $projdir/project.json
    set -l latest (stat -f '%m' $pf)
    for path in (jq -r '.repos[]?.path' $pf)
        set -l wt $projdir/$path
        test -d $wt; or continue
        set -l ct (git -C $wt log -1 --format=%ct 2>/dev/null)
        if test -n "$ct"; and test $ct -gt $latest
            set latest $ct
        end
    end
    echo $latest
end

function __work_status --description 'Local status of every project (no network)'
    set -l dirs ~/projects/*/
    if test (count $dirs) -eq 0
        echo "No projects yet."
        return 0
    end
    set -l TAB (printf '\t')
    set -l now (date +%s)
    for d in $dirs
        set -l projdir (string trim -r -c / -- $d)
        set -l name (basename $projdir)
        set -l pf $projdir/project.json
        if not test -f $pf
            printf '%-44s %s\n' $name '(no project.json -- work adopt)'
            continue
        end
        set -l sessions (jq -r '.sessions | length' $pf)
        set -l act (__work_activity $projdir)
        set -l age_days (math "floor(($now - $act) / 86400)")
        set -l repo_bits
        for path in (jq -r '.repos[]?.path' $pf)
            set -l wt $projdir/$path
            if not test -d $wt
                set -a repo_bits $path'[missing]'
                continue
            end
            set -l flags
            if test (count (git -C $wt status --porcelain 2>/dev/null)) -gt 0
                set -a flags dirty
            else
                set -a flags clean
            end
            set -l counts (
                git -C $wt rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null \
                    | string split $TAB
            )
            if test (count $counts) -eq 2
                test $counts[2] -gt 0; and set -a flags "+$counts[2]"
                test $counts[1] -gt 0; and set -a flags "-$counts[1]"
            else
                set -a flags no-upstream
            end
            set -a repo_bits $path'['(string join , $flags)']'
        end
        printf '%-44s %4sd %2d sess  %s\n' $name $age_days $sessions \
            (string join ' ' $repo_bits)
    end
end

function __work_archive --description 'Bundle transcripts, git evidence, and stray files into .archive/<name>.tar.gz'
    set -l projdir $argv[1]
    set -l pf $projdir/project.json
    set -l name (basename $projdir)
    set -l TAB (printf '\t')

    set -l stage_parent (mktemp -d)
    set -l stage $stage_parent/$name
    mkdir -p $stage

    jq --arg completed (date '+%Y-%m-%dT%H:%M') '.completed = $completed' $pf >$stage/project.json
    or begin
        rm -rf $stage_parent
        return 1
    end

    # Session transcripts. Claude Code prunes ~/.claude transcripts
    # after cleanupPeriodDays, so the archive is the durable copy.
    # Layout per session: <enc>/<id>.jsonl plus an optional <enc>/<id>/
    # sidecar dir (subagent transcripts).
    mkdir -p $stage/sessions
    for row in (jq -r '.sessions[]? | [.id, (.cwd // "")] | @tsv' $pf)
        set -l f (string split $TAB -- $row)
        set -l id $f[1]
        set -l cwd (string replace -r '^~' $HOME -- $f[2])
        test -n "$cwd"; or continue
        set -l enc (string replace -ar '[/._]' '-' -- $cwd)
        set -l src ~/.claude/projects/$enc/$id.jsonl
        if test -f $src
            cp $src $stage/sessions/
        else
            echo "Warning: transcript for session $id not found (already pruned?)" >&2
        end
        test -d ~/.claude/projects/$enc/$id
        and cp -R ~/.claude/projects/$enc/$id $stage/sessions/
    end

    # Per-repo git evidence, captured while branches still exist.
    for row in (jq -r '.repos[]? | [.path, (.branch // ""), (.base // "")] | @tsv' $pf)
        set -l f (string split $TAB -- $row)
        set -l wt $projdir/$f[1]
        set -l branch $f[2]
        set -l base $f[3]
        test -d $wt; or continue
        set -l rdir $stage/repos/$f[1]
        mkdir -p $rdir
        # Uncommitted tracked changes (only reachable via --force
        # teardown; the normal path blocks on a dirty tree).
        if test (count (git -C $wt status --porcelain 2>/dev/null)) -gt 0
            git -C $wt diff HEAD >$rdir/uncommitted.diff 2>/dev/null
        end
        if test -z "$branch" -o -z "$base"
            echo "branch/base unknown; no range artifacts captured" >$rdir/NOTE.txt
            continue
        end
        git -C $wt fetch --quiet origin $base 2>/dev/null
        set -l commits (git -C $wt rev-list --count origin/$base..$branch 2>/dev/null)
        if test -z "$commits" -o "$commits" = 0
            echo "no commits beyond origin/$base" >$rdir/NOTE.txt
            continue
        end
        git -C $wt diff origin/$base...$branch >$rdir/branch.diff
        git -C $wt log --stat origin/$base..$branch >$rdir/log.txt
        # A bundle is re-cloneable against any repo containing the
        # base commit -- survives origin branch deletion.
        git -C $wt bundle create $rdir/bundle.git origin/$base..$branch 2>/dev/null
        or echo "Warning: bundle failed for $f[1]" >&2
    end

    # Stray files: everything that isn't a registered repo checkout
    # or project.json (these are deleted by teardown otherwise).
    set -l known project.json .sandbox-sync
    for p in (jq -r '.repos[]?.path' $pf)
        set -a known $p
    end
    for entry in $projdir/* $projdir/.*
        contains -- (basename $entry) $known; and continue
        mkdir -p $stage/files
        cp -R $entry $stage/files/
    end

    mkdir -p ~/projects/.archive
    set -l dest ~/projects/.archive/$name.tar.gz
    test -e $dest; and set dest ~/projects/.archive/$name-(date +%Y%m%d%H%M%S).tar.gz
    tar -czf $dest -C $stage_parent $name
    or begin
        rm -rf $stage_parent
        echo "Archive creation failed." >&2
        return 1
    end
    rm -rf $stage_parent
    echo "Archived to "(string replace -- $HOME '~' $dest)
end

function __work_teardown --description 'Remove worktrees/clones, archive project.json, delete the dir'
    argparse f/force -- $argv
    set -l projdir $argv[1]
    set -l pf $projdir/project.json
    set -l name (basename $projdir)
    set -l TAB (printf '\t')

    set -l rows (
        jq -r '.repos[]? | [.path, .mode, (.source // ""), (.branch // "")] | @tsv' $pf
    )
    set -l known_paths project.json
    for row in $rows
        set -a known_paths (string split $TAB -- $row)[1]
    end

    set -l blockers
    for row in $rows
        set -l f (string split $TAB -- $row)
        set -l wt $projdir/$f[1]
        test -d $wt; or continue
        if test (count (git -C $wt status --porcelain 2>/dev/null)) -gt 0
            set -a blockers "$f[1]: uncommitted changes"
        end
        if test -n "$f[4]"
            if test (count (git -C $wt rev-list $f[4] --not --remotes 2>/dev/null)) -gt 0
                set -a blockers "$f[1]: unpushed commits on $f[4]"
            end
        end
    end
    # A git checkout not registered in project.json would be silently
    # rm -rf'd below; refuse until it's adopted (or forced). Hidden
    # dirs are scanned too: a pending .sandbox-sync must block.
    for child in $projdir/*/ $projdir/.*/
        set -l dir (string trim -r -c / -- $child)
        test -e $dir/.git; or continue
        set -l base (basename $dir)
        contains -- $base $known_paths; and continue
        if test $base = .sandbox-sync
            set -a blockers "$base: unfinished sandbox sync (finish or remove it)"
        else
            set -a blockers "$base: unregistered git checkout (work adopt first)"
        end
    end

    if test (count $blockers) -gt 0; and not set -q _flag_force
        echo "Refusing to tear down $name:" >&2
        printf '  %s\n' $blockers >&2
        echo "Resolve these or re-run with --force." >&2
        return 1
    end

    # Capture the complete archive BEFORE anything is deleted; a
    # failed archive aborts the teardown rather than losing data.
    __work_archive $projdir
    or return 1

    for row in $rows
        set -l f (string split $TAB -- $row)
        set -l wt $projdir/$f[1]
        test -d $wt; or continue
        switch $f[2]
            case worktree
                set -l src (string replace -r '^~' $HOME -- $f[3])
                set -l rm_args
                set -q _flag_force; and set rm_args --force
                git -C $src worktree remove $rm_args $wt
                or begin
                    echo "Failed to remove worktree $wt; aborting." >&2
                    return 1
                end
                if test -n "$f[4]"
                    # The unpushed-commit gate passed, so every commit is
                    # reachable from a remote ref; -D is safe if -d balks
                    # (e.g. the upstream was deleted after PR merge).
                    git -C $src branch -d $f[4] 2>/dev/null
                    or git -C $src branch -D $f[4]
                end
                git -C $src worktree prune
            case clone
                rm -rf $wt
        end
    end

    mkdir -p ~/projects/.archive
    set -l dest ~/projects/.archive/$name.json
    test -e $dest; and set dest ~/projects/.archive/$name-(date +%Y%m%d%H%M%S).json
    jq --arg completed (date '+%Y-%m-%dT%H:%M') '.completed = $completed' $pf >$dest

    string match -q "$projdir*" -- $PWD; and cd ~/projects
    rm -rf $projdir

    # Legacy-era cleanup: mark this project's todo.txt entries done,
    # in descending line order so auto-archive renumbering can't
    # shift later targets. Nothing writes todo.txt anymore; delete
    # this block once todo.sh/~/.tasks are retired.
    set -l todo ~/.tasks/todo.txt
    if test -f $todo; and command -q todo.sh
        set -l nums
        set -l n 0
        while read -l line
            set n (math $n + 1)
            string match -q 'x *' -- $line; and continue
            string match -qr "dir:~/projects/$name(/|\s|\$)" -- $line
            and set -a nums $n
        end <$todo
        for n in (printf '%s\n' $nums | sort -rn)
            test -n "$n"; and todo.sh do $n
        end
    end

    echo "Torn down $name (archived to "(string replace -- $HOME '~' $dest)")"
end

function __work_done --description 'Confirm and tear down a project'
    argparse f/force -- $argv
    set -l projdir
    if test -n "$argv[1]"
        set projdir (__work_find $argv[1])
        if test -z "$projdir"
            echo "No project matching $argv[1]" >&2
            return 1
        end
    else
        set -l pfile (__work_project_file (pwd))
        if test -z "$pfile"
            echo "Not inside a project; pass an id: work done ACT-123" >&2
            return 1
        end
        set projdir (dirname $pfile)
    end
    set -l pf $projdir/project.json
    if not test -f $pf
        echo "$projdir has no project.json; run work adopt first." >&2
        return 1
    end

    set -l name (basename $projdir)
    set -l TAB (printf '\t')
    echo "Tearing down $name will:"
    set -l known project.json
    for row in (jq -r '.repos[]? | [.path, .mode, (.branch // "")] | @tsv' $pf)
        set -l f (string split $TAB -- $row)
        set -a known $f[1]
        echo "  remove $f[2] $f[1] (branch: $f[3])"
    end
    for entry in $projdir/* $projdir/.*
        set -l base (basename $entry)
        contains -- $base $known; and continue
        echo "  delete stray: $base"
    end
    echo "  archive project.json, transcripts, diffs, and stray files"
    echo "    to ~/projects/.archive/ (json + tar.gz), then delete the dir"

    read -l -P "Proceed? [y/N] " confirm
    if test "$confirm" != y -a "$confirm" != Y
        echo "Aborted."
        return 1
    end
    set -l force_args
    set -q _flag_force; and set force_args --force
    __work_teardown $force_args $projdir
end

function __work_archives --description 'List archived projects, newest first'
    set -l TAB (printf '\t')
    set -l jsons ~/projects/.archive/*.json
    if test (count $jsons) -eq 0
        echo "No archives in ~/projects/.archive"
        return 0
    end
    for j in $jsons
        set -l name (basename $j .json)
        set -l completed (jq -r '.completed // "-"' $j)
        set -l title (jq -r '.title // empty' $j)
        set -l tarball -
        test -f ~/projects/.archive/$name.tar.gz; and set tarball tar.gz
        printf '%s\t%-44s %-16s %-6s %s\n' $completed $name $completed $tarball $title
    end | sort -r | cut -f2-
end

function __work_revive --description 'Restore an archived project from its tarball'
    set -l id $argv[1]
    if test -z "$id"
        echo "Usage: work revive <name or prefix>" >&2
        return 1
    end

    set -l tarball
    if test -f ~/projects/.archive/$id.tar.gz
        set tarball ~/projects/.archive/$id.tar.gz
    else
        set -l matches ~/projects/.archive/$id*.tar.gz
        if test (count $matches) -eq 0
            echo "No archive matching $id in ~/projects/.archive" >&2
            return 1
        end
        if test (count $matches) -gt 1
            echo "Multiple archives match $id; using the newest:" >&2
            printf '  %s\n' $matches >&2
        end
        set tarball (ls -t $matches | head -1)
    end

    set -l stage (mktemp -d)
    tar -xzf $tarball -C $stage
    or begin
        rm -rf $stage
        echo "Could not extract $tarball" >&2
        return 1
    end
    set -l srcroot (string trim -r -c / -- (ls -d $stage/*/)[1])
    set -l name (basename $srcroot)
    set -l projdir ~/projects/$name

    if test -e $projdir
        echo "$projdir already exists; nothing revived." >&2
        rm -rf $stage
        return 1
    end
    mkdir -p $projdir
    jq 'del(.completed)' $srcroot/project.json >$projdir/project.json

    if test -d $srcroot/files
        cp -R $srcroot/files/. $projdir/
    end

    # Transcripts go back into ~/.claude under each session's recorded
    # cwd encoding so resume-by-id works again. Never clobber a live
    # transcript that still exists there.
    set -l TAB (printf '\t')
    for row in (jq -r '.sessions[]? | [.id, (.cwd // "")] | @tsv' $projdir/project.json)
        set -l f (string split $TAB -- $row)
        set -l sess $f[1]
        set -l cwd (string replace -r '^~' $HOME -- $f[2])
        test -n "$cwd"; or continue
        set -l enc ~/.claude/projects/(string replace -ar '[/._]' '-' -- $cwd)
        mkdir -p $enc
        if not test -f $enc/$sess.jsonl
            test -f $srcroot/sessions/$sess.jsonl
            and cp $srcroot/sessions/$sess.jsonl $enc/
        end
        if not test -e $enc/$sess
            test -d $srcroot/sessions/$sess
            and cp -R $srcroot/sessions/$sess $enc/
        end
    end

    # Recreate each worktree. Branch source, in preference order:
    # still-local ref, origin, the archived bundle, the recorded
    # start commit (no-commit projects have no bundle).
    for row in (
        jq -r '.repos[]? | select(.mode == "worktree")
               | [.path, (.source // ""), (.branch // ""), (.start // "")] | @tsv' \
            $projdir/project.json
    )
        set -l f (string split $TAB -- $row)
        set -l path $f[1]
        set -l branch $f[3]
        set -l start $f[4]
        set -l src (string replace -r '^~' $HOME -- $f[2])
        if test -z "$src"; or not test -d "$src"
            echo "Warning: source for $path missing ($f[2]); worktree skipped" >&2
            continue
        end
        test -n "$branch"; or continue

        if not git -C $src show-ref --verify --quiet refs/heads/$branch
            git -C $src fetch --quiet origin $branch 2>/dev/null
            if git -C $src rev-parse --verify --quiet origin/$branch >/dev/null
                git -C $src branch $branch origin/$branch
            else if test -f $srcroot/repos/$path/bundle.git
                git -C $src fetch $srcroot/repos/$path/bundle.git "$branch:$branch"
            else if test -n "$start"
                git -C $src branch $branch $start
            end
        end
        if not git -C $src show-ref --verify --quiet refs/heads/$branch
            echo "Warning: could not recreate branch $branch for $path" >&2
            continue
        end
        if git -C $src worktree add $projdir/$path $branch
            __work_link_personal $projdir/$path $path
        else
            echo "Warning: worktree add failed for $path" >&2
        end
    end

    rm -rf $stage
    echo "Revived $name"
    cd $projdir
end

function __work_gc --description 'Flag and optionally tear down finished/stale projects'
    set -l now (date +%s)
    set -l idle_limit (math '30 * 86400')
    set -l TAB (printf '\t')
    set -l fetched
    set -l flagged 0
    for d in ~/projects/*/
        set -l projdir (string trim -r -c / -- $d)
        set -l name (basename $projdir)
        set -l pf $projdir/project.json
        test -f $pf; or continue
        set -l reasons

        set -l ticket (jq -r '.ticket // empty' $pf)
        if test -n "$ticket"
            set -l tstate (
                linear-cli i get $ticket -o json 2>/dev/null \
                    | jq -r '.state.name? // .state? // empty'
            )
            if contains -- "$tstate" Done Canceled Cancelled
                set -a reasons "ticket $ticket is $tstate"
            end
        end

        for row in (
            jq -r '.repos[]? | select(.mode == "worktree")
                   | [.path, (.source // ""), (.branch // ""),
                      (.base // ""), (.start // "")] | @tsv' $pf
        )
            set -l f (string split $TAB -- $row)
            set -l src (string replace -r '^~' $HOME -- $f[2])
            test -n "$src" -a -d "$src"; or continue
            if not contains -- $src $fetched
                git -C $src fetch --prune --quiet origin 2>/dev/null
                set -a fetched $src
            end
            # Merged = the tip moved past its recorded start AND is in
            # the base. Without a start (adopted project), skip -- the
            # upstream-gone / ticket / idle signals still apply.
            if test -n "$f[3]" -a -n "$f[4]" -a -n "$f[5]"
                set -l tip (git -C $src rev-parse --verify --quiet refs/heads/$f[3])
                if test -n "$tip" -a "$tip" != "$f[5]"
                    if git -C $src merge-base --is-ancestor $f[3] origin/$f[4] 2>/dev/null
                        set -a reasons "$f[1]: branch $f[3] merged into $f[4]"
                    end
                end
            end
            if test -n "$f[3]"
                git -C $src branch -vv --list $f[3] 2>/dev/null \
                    | string match -q '*: gone]*'
                and set -a reasons "$f[1]: upstream of $f[3] is gone (PR merged?)"
            end
        end

        set -l idle (math $now - (__work_activity $projdir))
        if test $idle -gt $idle_limit
            set -a reasons "idle "(math "floor($idle / 86400)")"d"
        end

        test (count $reasons) -eq 0; and continue
        set flagged (math $flagged + 1)
        echo $name
        printf '  %s\n' $reasons
        read -l -P "  Tear down $name? [y/N] " confirm
        if test "$confirm" = y -o "$confirm" = Y
            __work_teardown $projdir
            or echo "  Skipped (blocked); resolve, or 'work done $name --force'."
        end
    end
    test $flagged -eq 0; and echo "Nothing to clean up."
end

function __work_pick --description 'fzf picker over projects: enter resume, ctrl-d cd, ctrl-o ticket'
    set -l dirs ~/projects/*/
    if test (count $dirs) -eq 0
        echo "No projects yet. Start one: work ACT-123 --repo web"
        return 0
    end
    if not command -q fzf
        __work_list
        return
    end

    set -l TAB (printf '\t')
    set -l now (date +%s)
    set -l rows
    for d in $dirs
        set -l projdir (string trim -r -c / -- $d)
        set -l name (basename $projdir)
        set -l pf $projdir/project.json
        set -l title ''
        set -l sessions 0
        set -l act 0
        set -l age -
        if test -f $pf
            set title (jq -r '.title // empty' $pf)
            set sessions (jq -r '.sessions | length' $pf)
            set act (__work_activity $projdir)
            set age (math "floor(($now - $act) / 86400)")d
        end
        set -l display (printf '%-40s %4s %2d sess  %s' $name $age $sessions $title)
        set -a rows "$act$TAB$projdir$TAB$display"
    end

    set -l header 'enter:resume  ctrl-d:cd  ctrl-o:ticket  ctrl-x:done'
    set -l result (
        printf '%s\n' $rows | sort -rn \
            | fzf --delimiter=$TAB --with-nth=3 \
                --expect 'ctrl-d,ctrl-o,ctrl-x' \
                --header $header \
                --no-sort \
                --reverse
    )
    test -z "$result"; and return 0
    set -l key $result[1]
    set -l line $result[2]
    test -z "$line"; and return 0
    set -l projdir (string split $TAB -- $line)[2]

    switch "$key"
        case ''
            __work_resume $projdir
        case ctrl-d
            cd $projdir
            pwd
        case ctrl-x
            # Full done flow: summary, y/N confirm, safety gates.
            __work_done (basename $projdir)
        case ctrl-o
            set -l ticket (jq -r '.ticket // empty' $projdir/project.json 2>/dev/null)
            if test -z "$ticket"
                echo "No ticket on this project."
                return 0
            end
            set -l url (
                linear-cli i get $ticket -o json 2>/dev/null \
                    | jq -r '.url // empty'
            )
            if test -n "$url"
                open $url
            else
                echo "Could not open $ticket" >&2
            end
    end
end

function __work_list --description 'List projects under ~/projects'
    set -l dirs ~/projects/*/
    if test (count $dirs) -eq 0
        echo "No projects yet. Start one: work ACT-123 --repo web"
        return 0
    end
    for d in $dirs
        set -l name (basename $d)
        set -l title ''
        set -l sessions 0
        if test -f $d/project.json
            set title (jq -r '.title // empty' $d/project.json)
            set sessions (jq -r '.sessions | length' $d/project.json)
        end
        printf '%-44s %2d sessions  %s\n' $name $sessions $title
    end
end

function __work_help
    echo "work -- project lifecycle for LLM agent sessions"
    echo ""
    echo "  work                      fzf picker (enter:resume, ctrl-d:cd,"
    echo "                              ctrl-o:ticket, ctrl-x:done)"
    echo "  work list                 plain project listing"
    echo "  work <id> [options]       resume if it exists, else create"
    echo "  work .                    resume the project you're inside"
    echo "  work resume <pattern>     find a session by transcript text,"
    echo "                              pick in fzf, cd + resume it"
    echo "  work adopt                register the current directory"
    echo "  work promote <id> [opts]  convert the newest ad-hoc session in"
    echo "                              this directory into a new project"
    echo "                              (-s picks a specific session)"
    echo "  work add <repo> [-b BASE] add a repo worktree to the current"
    echo "                              project (scope expansion)"
    echo "  work status               dirty/ahead-behind/age per project"
    echo "  work done [id] [--force]  tear down + archive. id may be just"
    echo "                              the ticket (work done ACT-123); with"
    echo "                              no id, uses the project you're inside"
    echo "  work archives             list archived projects, newest first"
    echo "  work revive <id>          restore an archived project: dir,"
    echo "                              stray files, transcripts, worktrees"
    echo "  work gc                   flag finished/stale projects,"
    echo "                              prompt to tear each down"
    echo ""
    echo "Create options:"
    echo "  -r/--repo NAME    repo to include (repeatable, required)"
    echo "  -b/--base BRANCH  base branch for new feature branches"
    echo "  -n/--no-launch    prep the project but don't start a session"
    echo "  --no-claim        don't touch the Linear ticket (state/assignee)"
    echo "  --no-intake       sessions start blank (no intake prompt)"
    echo ""
    echo "Identifiers: a Linear ticket (ACT-123) or PREFIX-slug"
    echo "(CHORE-clean_dotfiles, ONCALL-sidekiq_alert) for untracked"
    echo "work. Ticketed projects require --repo; untracked ones may"
    echo "omit it for a repo-less scratch project."
end

function work --description 'Project lifecycle: create/resume/adopt LLM agent projects'
    mkdir -p ~/projects
    if test (count $argv) -eq 0
        __work_pick
        return
    end
    switch $argv[1]
        case list
            __work_list
        case .
            set -l pfile (__work_project_file (pwd))
            if test -z "$pfile"
                echo "Not inside a ~/projects project." >&2
                return 1
            end
            __work_resume (dirname $pfile)
        case resume
            __work_session_search $argv[2..]
        case adopt
            __work_adopt $argv[2..]
        case promote
            __work_promote $argv[2..]
        case add
            __work_add $argv[2..]
        case status
            __work_status
        case done
            __work_done $argv[2..]
        case archives
            __work_archives
        case revive
            __work_revive $argv[2..]
        case gc
            __work_gc
        case -h --help
            __work_help
        case '*'
            __work_start $argv
    end
end
