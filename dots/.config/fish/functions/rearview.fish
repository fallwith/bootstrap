function rearview --description 'Review and optionally publish a GitHub pull request'
    switch $argv[1]
        case init doctor
            python3 /Users/jamesbunch/.codex/skills/rearview/scripts/rearviewcodex.py $argv
        case '*'
            python3 /Users/jamesbunch/.codex/skills/rearview/scripts/rearviewcodex.py \
                --model gpt-6-astra --reasoning-effort high $argv
    end
end
