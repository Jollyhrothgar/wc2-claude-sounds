#!/usr/bin/env bash
# uninstall.sh - Uninstall Warcraft II Claude Code sound hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOOKS_DIR="${HOME}/.config/claude/hooks"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"

echo "Uninstalling Warcraft II Claude Code sound hooks..."

# Define hook names
HOOK_NAMES=("SessionStart" "PreToolUse" "PostToolUse" "Notification" "SessionEnd")

# Remove hooks
for hook_name in "${HOOK_NAMES[@]}"; do
    target_path="$CLAUDE_HOOKS_DIR/$hook_name"

    if [[ -L "$target_path" ]]; then
        # It's a symlink - check if it points to our repo
        link_target=$(readlink "$target_path")
        if [[ "$link_target" == "$SCRIPT_DIR"/hooks/* ]]; then
            rm "$target_path"
            echo "  ✓ Removed $hook_name"
        else
            echo "  ⚠ $hook_name is a symlink but doesn't point to this repo, skipping"
        fi
    elif [[ -e "$target_path" ]]; then
        echo "  ⚠ $hook_name exists but is not a symlink, skipping"
    else
        echo "  - $hook_name not installed"
    fi
done

# Clean up lock directory
LOCK_DIR=$(grep -A1 "lock_dir:" "$CONFIG_FILE" | tail -1 | sed 's/.*: //' | tr -d '"' | xargs)
if [[ -d "$LOCK_DIR" ]]; then
    echo ""
    read -p "Remove lock directory ($LOCK_DIR)? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$LOCK_DIR"
        echo "  ✓ Removed lock directory"
    fi
fi

echo ""
echo "Uninstall complete!"
