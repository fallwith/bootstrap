function qwen -d 'Frontend for Ollama based Qwen'
    set -l model "qwen2.5-coder:7b"
    set -l instructions ""

    # check for the -r (raw) flag
    if contains -- -r $argv
        set instructions ". Output ONLY raw code or text. No markdown, no chatter."
        # remove the flag from the arguments so it doesn't get sent to the model
        set -e argv[(contains -i -- -r $argv)]
    end

    if not set -q argv[1]
        echo "Usage: qwen [-r] 'prompt' [file]"
        echo "Options: -r  Raw output (no markdown/chatter)"
        return 1
    end

    set -l prompt "$argv[1]$instructions"

    if test (count $argv) -ge 2
        # file provided
        cat $argv[2] | ollama run $model $prompt
    else if not isatty stdin
        # piped input
        cat | ollama run $model $prompt
    else
        # just prompt
        ollama run $model $prompt
    end
end
