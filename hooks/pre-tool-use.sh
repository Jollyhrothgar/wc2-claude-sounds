#!/usr/bin/env bash
# Claude Code PreToolUse hook - Play acknowledgment sound when starting a task

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if character is set
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    exit 0
fi

# Play acknowledge sound (with Ready as fallback)
"$REPO_ROOT/scripts/play_sound.sh" "Acknowledge" "Ready" &

exit 0
