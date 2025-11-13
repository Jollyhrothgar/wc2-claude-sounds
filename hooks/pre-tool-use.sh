#!/usr/bin/env bash
# Claude Code PreToolUse hook - Play acknowledgment sound when starting a task

set -euo pipefail

# Resolve symlink to get real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
WC2_SOUNDS_REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if character is set
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    exit 0
fi

# Play acknowledge sound (with Ready as fallback)
"$WC2_SOUNDS_REPO_ROOT/scripts/play_sound.sh" "Acknowledge" "Ready" &

exit 0
