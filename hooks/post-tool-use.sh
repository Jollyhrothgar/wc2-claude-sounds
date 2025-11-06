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

# Get or create character for this session
# Use PPID (parent process, Claude Code) for session consistency
SESSION_FILE="/tmp/wc2-character-$PPID"
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    # Check if we have a session file
    if [[ -f "$SESSION_FILE" ]]; then
        WC2_CHARACTER=$(cat "$SESSION_FILE")
    else
        # Select new character and save to session file
        WC2_CHARACTER=$("$REPO_ROOT/scripts/select_character.sh" 2>/dev/null || echo "Peasant")
        echo "$WC2_CHARACTER" > "$SESSION_FILE"
    fi
    export WC2_CHARACTER
fi

# NOTE: Claude Code doesn't seem to pass duration info to PostToolUse hooks
# So we can't filter by min_duration. Just play the sound for all tool completions.

# Play complete sound
"$REPO_ROOT/scripts/play_sound.sh" "Complete" &

exit 0
