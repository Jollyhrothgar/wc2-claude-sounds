#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook - Play acknowledgment when user submits prompt
# This hook runs when the user submits a message, before Claude processes it

# Run everything in background to avoid blocking
(
    set -uo pipefail

    # DEBUG
    echo "UserPromptSubmit called at $(date) by PID $$ from PPID $PPID" >> /tmp/wc2-hook-calls.log 2>&1

    # Resolve symlink to get real script location
    SCRIPT_PATH="${BASH_SOURCE[0]}"
    if [[ -L "$SCRIPT_PATH" ]]; then
        SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    fi
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    WC2_SOUNDS_REPO_ROOT="$(dirname "$SCRIPT_DIR")"

    # Get character for this session
    SESSION_FILE="/tmp/wc2-character-$PPID"
    if [[ -z "${WC2_CHARACTER:-}" ]]; then
        if [[ -f "$SESSION_FILE" ]]; then
            WC2_CHARACTER=$(cat "$SESSION_FILE")
        else
            # Fallback if no session file
            WC2_CHARACTER="Peasant"
        fi
    fi
    export WC2_CHARACTER

    # Play acknowledge sound
    echo "About to play Acknowledge for character: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
    "$WC2_SOUNDS_REPO_ROOT/scripts/play_sound.sh" "Acknowledge" >> /tmp/wc2-hook-calls.log 2>&1
    echo "Acknowledge sound played for $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
) &

exit 0
