#!/usr/bin/env bash
# select_character.sh - Randomly select an available WC2 character for this shell session
# Creates lock file to prevent same character in multiple terminal windows

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WC2_SOUNDS_REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$WC2_SOUNDS_REPO_ROOT/config.yaml"
LABELS_FILE="$WC2_SOUNDS_REPO_ROOT/sounds/labels.json"

# Read config values (simple YAML parsing for our needs)
LOCK_DIR=$(grep "lock_dir:" "$CONFIG_FILE" | sed 's/.*lock_dir: *//' | tr -d '"' | xargs)
STALE_HOURS=$(grep "stale_lock_hours:" "$CONFIG_FILE" | sed 's/.*stale_lock_hours: *//' | sed 's/#.*//' | xargs)
LOCKING_ENABLED=$(grep -A2 "^locking:" "$CONFIG_FILE" | grep "enabled:" | sed 's/.*enabled: *//' | xargs)

# Create lock directory if needed
if [[ "$LOCKING_ENABLED" == "true" ]]; then
    mkdir -p "$LOCK_DIR"

    # Clean up stale locks (PIDs that no longer exist or older than stale_lock_hours)
    find "$LOCK_DIR" -name "*.lock" -type f 2>/dev/null | while read -r lockfile; do
        if [[ -f "$lockfile" ]]; then
            lock_pid=$(cat "$lockfile")
            lock_age_hours=$(( ($(date +%s) - $(stat -f %m "$lockfile" 2>/dev/null || echo 0)) / 3600 ))

            # Remove if PID doesn't exist or lock is too old
            if ! kill -0 "$lock_pid" 2>/dev/null || [[ "$lock_age_hours" -gt "$STALE_HOURS" ]]; then
                rm -f "$lockfile"
            fi
        fi
    done
fi

# Get all available unit types from labels.json
all_characters=$(jq -r '
    .sounds[]
    | select(.category == "unit" and .faction != null and .["Unit Type"] != null and .["Unit Type"] != "null")
    | .["Unit Type"]
' "$LABELS_FILE" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u)

# Read disabled characters from config
disabled_characters=$(grep -A100 "disabled_characters:" "$CONFIG_FILE" | grep "^  - " | sed 's/^  - //' | sed 's/ *#.*//' | xargs)

# Filter out disabled characters
available_characters=()
while IFS= read -r char; do
    if [[ -n "$char" ]]; then
        is_disabled=false
        for disabled in $disabled_characters; do
            if [[ "$char" == "$disabled" ]]; then
                is_disabled=true
                break
            fi
        done

        if [[ "$is_disabled" == "false" ]]; then
            available_characters+=("$char")
        fi
    fi
done <<< "$all_characters"

# Filter out locked characters if locking is enabled
if [[ "$LOCKING_ENABLED" == "true" ]]; then
    unlocked_characters=()
    for char in "${available_characters[@]}"; do
        lock_file="$LOCK_DIR/$(echo "$char" | sed 's/ /_/g').lock"
        if [[ ! -f "$lock_file" ]]; then
            unlocked_characters+=("$char")
        fi
    done
    available_characters=("${unlocked_characters[@]}")
fi

# Check if we have any characters left
if [[ ${#available_characters[@]} -eq 0 ]]; then
    echo "ERROR: No available characters! All are either disabled or locked." >&2
    exit 1
fi

# Randomly select a character
selected_index=$((RANDOM % ${#available_characters[@]}))
selected_character="${available_characters[$selected_index]}"

# Create lock file with current shell PID if locking is enabled
if [[ "$LOCKING_ENABLED" == "true" ]]; then
    lock_file="$LOCK_DIR/$(echo "$selected_character" | sed 's/ /_/g').lock"
    echo "$$" > "$lock_file"
fi

# Output the selected character (will be captured by calling script)
echo "$selected_character"
