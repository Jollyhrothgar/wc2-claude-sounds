#!/usr/bin/env bash
# Claude Code Notification hook - Play alert sound when Claude needs attention

set -euo pipefail

# Resolve symlink to get real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if character is set
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    exit 0
fi

# Play alert sound (with Annoyed as fallback)
"$REPO_ROOT/scripts/play_sound.sh" "Alert" "Annoyed" &

exit 0
