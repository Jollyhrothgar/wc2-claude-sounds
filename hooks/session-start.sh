#!/usr/bin/env bash
# Claude Code SessionStart hook - Select character and play greeting
# This hook runs when a new Claude Code session starts

set -uo pipefail  # Removed -e to prevent silent failures

# DEBUG
echo "SessionStart called at $(date) by PID $$ from PPID $PPID" >> /tmp/wc2-hook-calls.log 2>&1

# Resolve symlink to get real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Select a character for this session and save to session file
# Use PPID (parent process, Claude Code) for session consistency
SESSION_FILE="/tmp/wc2-character-$PPID"

# Select character with error handling
if WC2_CHARACTER=$("$REPO_ROOT/scripts/select_character.sh" 2>&1); then
    echo "$WC2_CHARACTER" > "$SESSION_FILE"
    export WC2_CHARACTER
    echo "Selected character: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1

    # Play greeting sound in background to avoid blocking
    "$REPO_ROOT/scripts/play_sound.sh" "Greeting" >> /tmp/wc2-hook-calls.log 2>&1 &
    echo "Greeting sound started in background (PID $!)" >> /tmp/wc2-hook-calls.log 2>&1
else
    echo "ERROR: Failed to select character: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
fi

exit 0
