#!/usr/bin/env bash
# Claude Code SessionEnd hook - Clean up character lock file

set -euo pipefail

# Resolve symlink to get real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_ROOT/config.yaml"

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

# Get lock directory from config
LOCK_DIR=$(grep -A1 "lock_dir:" "$CONFIG_FILE" | tail -1 | sed 's/.*: //' | tr -d '"' | xargs)

# Remove lock file for this character
LOCK_FILE="$LOCK_DIR/$(echo "$WC2_CHARACTER" | sed 's/ /_/g').lock"
if [[ -f "$LOCK_FILE" ]]; then
    # Verify it's our lock (matches our PID)
    if [[ "$(cat "$LOCK_FILE")" == "$$" ]]; then
        rm -f "$LOCK_FILE"
    fi
fi

# Remove session file
rm -f "$SESSION_FILE"

exit 0
