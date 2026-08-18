function __resumecodex_first_prompt --description 'Extract a recognizable opening prompt from a Codex session jsonl'
    set -l f $argv[1]
    test -r "$f"; or return 1

    # Older Codex sessions record user-typed prompts separately from injected
    # context. Prefer that record when it is available.
    set -l first (head -200 $f \
    | jq -r '
        select(
          .type == "event_msg"
          and .payload.type == "user_message"
          and (.payload.message | type) == "string"
        )
        | .payload.message | gsub("\n"; " ") | gsub("\t"; " ")
      ' 2>/dev/null \
    | head -1)

    # Current sessions store prompts as response items. Skip context Codex
    # injects into the user role before the user's opening prompt.
    if test -z "$first"
        set first (head -200 $f \
        | jq -r '
            select(.type == "response_item" and .payload.role == "user")
            | .payload.content[]?
            | select(.type == "input_text" and (.text | type) == "string")
            | .text
            | select(
                (startswith("# AGENTS.md instructions") or
                 startswith("<environment_context>")) | not
              )
            | gsub("\n"; " ") | gsub("\t"; " ")
          ' 2>/dev/null \
        | head -1)
    end

    test -z "$first"; and return 0
    string sub -l 200 -- $first
end

function resumecodex --description 'Perform a text search to find a previous Codex session, then cd to its project and resume it'
    if test (count $argv) -eq 0
        echo "usage: resumecodex <pattern>" >&2
        return 1
    end
    for cmd in fzf jq codex
        if not command -q $cmd
            echo "resumecodex requires $cmd" >&2
            return 1
        end
    end

    # Pick a recursive-grep flavor (decreasing rarity).
    set -l grep_cmd
    if command -q ug
        set grep_cmd ug -ilr
    else if command -q rg
        set grep_cmd rg -il
    else if command -q grep
        set grep_cmd grep -rli
    else
        echo "resumecodex requires ug, rg, or grep" >&2
        return 1
    end

    # Detect GNU coreutils vs BSD for stat/date (Linux vs macOS/BSD).
    set -l gnu_stat 0
    stat --version >/dev/null 2>&1; and set gnu_stat 1
    set -l gnu_date 0
    date --version >/dev/null 2>&1; and set gnu_date 1

    set -l line ($grep_cmd -- $argv[1] ~/.codex/sessions/ \
    | while read -l f
        set -l meta (head -50 $f \
        | jq -r '
            select(.type == "session_meta")
            | [(.payload.id // .payload.session_id // ""),
               (.payload.cwd // ""),
               (.payload.originator // "")]
            | @tsv
          ' 2>/dev/null \
        | head -1)
        set -l meta_parts (string split \t -- $meta)
        set -l session $meta_parts[1]
        set -l proj $meta_parts[2]
        set -l originator $meta_parts[3]

        # Match Codex's default picker by excluding non-interactive sessions.
        test "$originator" = codex_exec; and continue
        if test -z "$session" -o -z "$proj"
            echo "resumecodex: missing session metadata in $f; skipping" >&2
            continue
        end

        set -l mtime
        if test $gnu_stat -eq 1
            set mtime (stat -c '%Y' $f)
        else
            set mtime (stat -f '%m' $f)
        end
        set -l iso
        if test $gnu_date -eq 1
            set iso (date -d "@$mtime" '+%Y-%m-%d %H:%M:%S')
        else
            set iso (date -r $mtime '+%Y-%m-%d %H:%M:%S')
        end

        set -l prompt (__resumecodex_first_prompt $f)
        printf '%s\t%s\t%s\t%s\t%s\n' $mtime $iso $session $proj $prompt
      end \
    | sort -rn | cut -f2- \
    | fzf --ansi --delimiter=\t --with-nth=1,3,4 \
          --header='time / project / first prompt')
    test -z "$line"; and return 1

    set -l parts (string split \t -- $line)
    set -l session $parts[2]
    set -l proj $parts[3]
    if not test -d "$proj"
        echo "Project directory not found: $proj" >&2
        return 1
    end

    cd $proj
    and codex resume $session
end
