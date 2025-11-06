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

# Check if character is set, if not select one
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    export WC2_CHARACTER=$("$REPO_ROOT/scripts/select_character.sh" 2>/dev/null || echo "Peasant")
fi

# NOTE: Claude Code doesn't seem to pass duration info to PostToolUse hooks
# So we can't filter by min_duration. Just play the sound for all tool completions.

# Play complete sound
"$REPO_ROOT/scripts/play_sound.sh" "Complete" &

exit 0
