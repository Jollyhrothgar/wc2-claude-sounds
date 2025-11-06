#!/usr/bin/env bash
# Claude Code PostToolUse hook - Play completion sound when task finishes

set -euo pipefail

# Resolve symlink to get real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_ROOT/config.yaml"

# Check if character is set
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    exit 0
fi

# Get minimum duration setting (only play for long-running tasks)
MIN_DURATION=$(grep -A5 "^playback:" "$CONFIG_FILE" | grep "min_duration_for_complete:" | sed 's/.*: //' | xargs)

# Hook input comes via stdin - parse the JSON for task duration
# (Claude Code passes hook context as JSON)
if command -v jq &> /dev/null; then
    # If we can get duration from the hook context, check it
    # Otherwise just play the sound
    TASK_DURATION=$(jq -r '.duration // 0' 2>/dev/null || echo "999")

    if (( $(echo "$TASK_DURATION < $MIN_DURATION" | bc -l 2>/dev/null || echo 0) )); then
        # Task was too quick, skip sound
        exit 0
    fi
fi

# Play complete sound
"$REPO_ROOT/scripts/play_sound.sh" "Complete" &

exit 0
