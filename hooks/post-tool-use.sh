#!/usr/bin/env bash
# Claude Code PostToolUse hook - Play completion sound when task finishes

set -euo pipefail

# DEBUG
echo "PostToolUse called at $(date) by PID $$ from PPID $PPID" >> /tmp/wc2-hook-calls.log

# Prevent multiple sounds in quick succession (debounce)
# Only play if >10 seconds since last play
LAST_PLAY_FILE="/tmp/wc2-last-play-$PPID"
CURRENT_TIME=$(date +%s)
if [[ -f "$LAST_PLAY_FILE" ]]; then
    LAST_TIME=$(cat "$LAST_PLAY_FILE")
    TIME_DIFF=$((CURRENT_TIME - LAST_TIME))
    if [[ $TIME_DIFF -lt 10 ]]; then
        echo "Debounced (${TIME_DIFF}s since last play)" >> /tmp/wc2-hook-calls.log
        exit 0
    fi
fi
echo "$CURRENT_TIME" > "$LAST_PLAY_FILE"

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

# Play complete sound with fallbacks (not all characters have "Complete")
# Try: Complete -> Ready -> Acknowledge -> Greeting
"$REPO_ROOT/scripts/play_sound.sh" "Complete" "Ready" "Acknowledge" "Greeting" &

exit 0
