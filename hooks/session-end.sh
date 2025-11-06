#!/usr/bin/env bash
# Claude Code SessionEnd hook - Clean up character lock file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_ROOT/config.yaml"

# Check if character is set
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    exit 0
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

exit 0
