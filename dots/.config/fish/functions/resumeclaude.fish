function __resumeclaude_decode_proj --description 'Reverse Claude Code project-dir encoding back to a real filesystem path'
    set -l encoded $argv[1]
    test -z "$encoded"; and return 1
    set -l rest $encoded
    if string match -q -- '-*' $rest
        set rest (string sub -s 2 -- $rest)
    end
    set -l tokens (string split -- '-' $rest)
    set -l path /
    while test (count $tokens) -gt 0
        set -l n (count $tokens)
        set -l best 0
        # Find the longest prefix of tokens that joins (with '-') into an
        # existing directory under $path. Hyphens are ambiguous (they encode
        # both '/' and literal '-'), so we probe the filesystem.
        for i in (seq 1 $n)
            set -l try $path(string join -- '-' $tokens[1..$i])
            if test -d $try
                set best $i
            end
        end
        if test $best -eq 0
            # No prefix exists -- glom remaining tokens and bail.
            set path $path(string join -- '-' $tokens)
            set tokens
        else if test $best -eq $n
            set path $path(string join -- '-' $tokens[1..$best])
            set tokens
        else
            set path $path(string join -- '-' $tokens[1..$best])/
            set tokens $tokens[(math $best + 1)..-1]
        end
    end
    echo $path
end

function __resumeclaude_first_prompt --description 'Extract a recognizable opening prompt from a Claude Code session jsonl'
    set -l f $argv[1]
    test -r "$f"; or return 1
    # Pull user-typed string content with newlines/tabs flattened so each
    # logical message is one element when read by fish.
    set -l prompts (head -200 $f \
    | jq -r '
        select(.type=="user" and (.message.content | type) == "string")
        | .message.content | gsub("\n"; " ") | gsub("\t"; " ")
      ' 2>/dev/null)
    set -l slash ''
    set -l first ''
    for line in $prompts
        # Render slash-command invocations as "/cmd args" rather than skipping them.
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

function resumeclaude --description 'Perform a text search to find a previous Claude session, then cd to its project and resume it'
    if test (count $argv) -eq 0
        echo "usage: resumeclaude <pattern>" >&2
        return 1
    end
    for cmd in fzf jq claude
        if not command -q $cmd
            echo "resumeclaude requires $cmd" >&2
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
        echo "resumeclaude requires ug, rg, or grep" >&2
        return 1
    end
    # Detect GNU coreutils vs BSD for stat/date (Linux vs macOS/BSD).
    set -l gnu_stat 0
    stat --version >/dev/null 2>&1; and set gnu_stat 1
    set -l gnu_date 0
    date --version >/dev/null 2>&1; and set gnu_date 1
    set -l line ($grep_cmd $argv[1] ~/.claude/projects/ \
    | grep -v '/subagents/' \
    | while read -l f
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
        set -l encoded (basename (dirname $f))
        set -l proj (__resumeclaude_decode_proj $encoded)
        set -l session (basename $f .jsonl)
        set -l prompt (__resumeclaude_first_prompt $f)
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
    and claude --resume $session
end
