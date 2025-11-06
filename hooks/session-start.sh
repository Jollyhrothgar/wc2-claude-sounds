#!/usr/bin/env bash
# Claude Code SessionStart hook - Select character and play greeting
# This hook runs when a new Claude Code session starts

set -euo pipefail

# Resolve symlink to get real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Select a character for this session
WC2_CHARACTER=$("$REPO_ROOT/scripts/select_character.sh")

if [[ -z "$WC2_CHARACTER" ]]; then
    exit 0
fi

# Export character for this session (will be inherited by hook scripts)
export WC2_CHARACTER

# Play greeting sound
"$REPO_ROOT/scripts/play_sound.sh" "Greeting" &

# Output JSON to set environment variable for the session
# This makes WC2_CHARACTER available to all subsequent hooks
cat <<EOF
{
  "env": {
    "WC2_CHARACTER": "$WC2_CHARACTER"
  }
}
EOF
