function ghostty_theme -d 'Cycle Ghostty theme'
    set -l themes \
        'Catppuccin Frappe' \
        'Catppuccin Macchiato' \
        'Rose Pine Moon' \
        'TokyoNight Storm' \
        'Everforest Dark Hard' \
        'Nightfox' \
        'Nordfox'
    set -l current (string replace 'theme = ' '' < ~/.config/ghostty/theme.conf)
    set -l idx 0
    for i in (seq (count $themes))
        if test "$themes[$i]" = "$current"
            set idx $i
            break
        end
    end
    set -l next (math $idx % (count $themes) + 1)
    set -l pick $themes[$next]
    echo "theme = $pick" > ~/.config/ghostty/theme.conf
    osascript -e 'tell application "System Events" to keystroke "," using {command down, shift down}'
    echo "Switched to: $pick ($next/"(count $themes)")"
end
