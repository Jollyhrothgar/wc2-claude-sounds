#!/usr/bin/env bash
# Claude Code SessionEnd hook - Play death sound and clean up session

set -euo pipefail

# DEBUG
echo "SessionEnd called at $(date) by PID $$ from PPID $PPID" >> /tmp/wc2-hook-calls.log 2>&1

# Resolve symlink to get real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
WC2_SOUNDS_REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$WC2_SOUNDS_REPO_ROOT/config.yaml"

# Get character from session file if not in env
# Use PPID (parent process, Claude Code) for session consistency
SESSION_FILE="/tmp/wc2-character-$PPID"
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    if [[ -f "$SESSION_FILE" ]]; then
        WC2_CHARACTER=$(cat "$SESSION_FILE")
    else
        # No character was ever set, nothing to clean up
        exit 0
    fi
fi
export WC2_CHARACTER

# Play death sound with fallbacks (Death -> Annoyed -> Acknowledge)
# Play synchronously so it doesn't get cut off on exit
echo "About to play Death for character: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
"$WC2_SOUNDS_REPO_ROOT/scripts/play_sound.sh" "Death" "Annoyed" "Acknowledge" >> /tmp/wc2-hook-calls.log 2>&1
echo "Death sound played for $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1

# Get lock directory from config
LOCK_DIR=$(grep "lock_dir:" "$CONFIG_FILE" | sed 's/.*lock_dir: *//' | tr -d '"' | xargs)

# Note: Lock files are intentionally NOT removed here
# They contain the shell PID and should persist for the entire shell session
# They're cleaned up by stale lock cleanup in select_character.sh when the shell PID dies

# Remove session file
rm -f "$SESSION_FILE"

exit 0
