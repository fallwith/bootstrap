#!/bin/zsh

# ==========================================
# CONFIGURATION
# ==========================================
SRC_DIR="/Users/fallwith/Library/Application Support/minecraft/saves/Ejoslallap"
LOOP_INTERVAL=300

# Resolve the directory where this script lives dynamically
BACKUP_ROOT="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$BACKUP_ROOT/.last_state"
SLOT_FILE="$BACKUP_ROOT/.last_slot"
LOG_FILE="$BACKUP_ROOT/run.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Initializing local rolling backup loop in: $BACKUP_ROOT" >> "$LOG_FILE"

# Bulletproof Fallback: Find the slot containing the oldest .timestamp file
get_oldest_slot() {
    local slots=($BACKUP_ROOT/slot_*(N))
    
    # If we have fewer than 10 folders, pick the lowest empty slot number first
    if [ ${#slots} -lt 10 ]; then
        for i in {0..9}; do
            if [ ! -d "$BACKUP_ROOT/slot_$i" ]; then
                echo "$i"
                return
            fi
        done
    fi

    # If all 10 slots exist, look at the .timestamp files inside them
    # (om[-1]) sorts matching files by modification time and picks the oldest
    local oldest_timestamp_file=($BACKUP_ROOT/slot_*/.timestamp(Nom[-1]))

    if [ -n "$oldest_timestamp_file" ]; then
        # Extract the slot number from the path (e.g., .../slot_4/.timestamp -> 4)
        local parent_dir=$(dirname "$oldest_timestamp_file")
        echo "${parent_dir##*_}"
        return
    fi

    # Ultimate fallback if no .timestamp files exist yet
    echo "0"
}

# Core backup routine wrapped in a function for reuse
run_backup() {
    local force_backup=$1

    # 1. Capture the modification status of the source directory
    CURRENT_STATE=$(rclone size "$SRC_DIR" 2>/dev/null | grep -E 'Total size|Total objects')

    if [ -z "$CURRENT_STATE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Source directory missing." >> "$LOG_FILE"
        return 1
    fi

    # 2. Check for structural changes
    LAST_STATE=""
    [ -f "$STATE_FILE" ] && LAST_STATE=$(cat "$STATE_FILE")

    # If forced via Ctrl+C, skip the state check and execute anyway
    if [ "$CURRENT_STATE" = "$LAST_STATE" ] && [ "$force_backup" != "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - No changes detected. Skipping." >> "$LOG_FILE"
    else
        if [ "$force_backup" = "true" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Interrupt received! Forcing final backup..." >> "$LOG_FILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Changes detected!" >> "$LOG_FILE"
        fi

        # Determine target slot
        if [ -f "$SLOT_FILE" ]; then
            CURRENT_SLOT=$(cat "$SLOT_FILE")
        else
            echo "Slot tracking file missing. Detecting oldest restore point via markers..." >> "$LOG_FILE"
            CURRENT_SLOT=$(get_oldest_slot)
            echo "Determined oldest restore point is slot_$CURRENT_SLOT" >> "$LOG_FILE"
        fi

        TARGET_DIR="$BACKUP_ROOT/slot_$CURRENT_SLOT"
        echo "Syncing to $TARGET_DIR..." >> "$LOG_FILE"
        
        # 3. Perform the local sync
        rclone sync "$SRC_DIR" "$TARGET_DIR" --links

        # 4. Force a precise timestamp update on our marker file
        touch "$TARGET_DIR/.timestamp"

        # 5. Save state and increment pointer
        echo "$CURRENT_STATE" > "$STATE_FILE"
        
        NEXT_SLOT=$(( (CURRENT_SLOT + 1) % 10 ))
        echo "$NEXT_SLOT" > "$SLOT_FILE"
        echo "Sync complete. Next change will overwrite slot_$NEXT_SLOT." >> "$LOG_FILE"
    fi
    return 0
}

# Intercept Ctrl+C (SIGINT)
cleanup_and_force_backup() {
    echo "\n[Interrupt] Performing immediate shutdown backup..."
    run_backup "true"
    echo "Final backup complete. Exiting cleanly." >> "$LOG_FILE"
    exit 0
}
trap cleanup_and_force_backup SIGINT

# ==========================================
# MAIN LOOP
# ==========================================
while true; do
    run_backup "false"
    
    # Sleep in the background to ensure trap catches Ctrl+C immediately
    sleep "$LOOP_INTERVAL" & wait $!
done
