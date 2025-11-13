#!/usr/bin/env bash
# Claude Code SessionStart hook - Select character and play greeting
# This hook runs when a new Claude Code session starts

# Capture PPID before backgrounding (will be lost in subshell)
CLAUDE_PPID=$PPID

# Run everything in background to avoid blocking Claude Code startup
# This is especially important when Claude shows prompts (e.g., home directory warning)
(
    set -uo pipefail  # Removed -e to prevent silent failures

    # DEBUG
    echo "SessionStart called at $(date) by PID $$ from PPID $CLAUDE_PPID" >> /tmp/wc2-hook-calls.log 2>&1

    # Resolve symlink to get real script location
    SCRIPT_PATH="${BASH_SOURCE[0]}"
    if [[ -L "$SCRIPT_PATH" ]]; then
        SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    fi
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    WC2_SOUNDS_REPO_ROOT="$(dirname "$SCRIPT_DIR")"

    # Get or create character for this session
    # Use PPID (parent process, Claude Code) for session consistency
    SESSION_FILE="/tmp/wc2-character-$CLAUDE_PPID"

    # Check if character is already set (from shell init.sh)
    if [[ -z "${WC2_CHARACTER:-}" ]]; then
        # Not set in environment, check if we have a session file
        if [[ -f "$SESSION_FILE" ]]; then
            WC2_CHARACTER=$(cat "$SESSION_FILE")
            echo "Restored character from session: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
        else
            # Select new character and save to session file
            if WC2_CHARACTER=$("$WC2_SOUNDS_REPO_ROOT/scripts/select_character.sh" 2>&1); then
                echo "Selected new character: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
            else
                echo "ERROR: Failed to select character: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
                exit 0
            fi
        fi
    else
        echo "Using character from environment: $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
    fi

    # Save to session file for consistency across all hooks
    echo "$WC2_CHARACTER" > "$SESSION_FILE"
    export WC2_CHARACTER

    # Play greeting sound with fallbacks (Greeting -> Annoyed -> Ready -> Silly)
    "$WC2_SOUNDS_REPO_ROOT/scripts/play_sound.sh" "Greeting" "Annoyed" "Ready" "Silly" >> /tmp/wc2-hook-calls.log 2>&1
    echo "Greeting sound played for $WC2_CHARACTER" >> /tmp/wc2-hook-calls.log 2>&1
) &

# Exit immediately so hook doesn't block Claude Code startup
exit 0
