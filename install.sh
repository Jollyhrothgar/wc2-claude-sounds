#!/usr/bin/env bash
# install.sh - Install Warcraft II Claude Code sound hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOOKS_DIR="${HOME}/.config/claude/hooks"

echo "Installing Warcraft II Claude Code sound hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "$CLAUDE_HOOKS_DIR"

# Define hook mappings (repo hook file -> Claude hook name)
declare -A HOOKS=(
    ["session-start.sh"]="SessionStart"
    ["pre-tool-use.sh"]="PreToolUse"
    ["post-tool-use.sh"]="PostToolUse"
    ["notification.sh"]="Notification"
    ["session-end.sh"]="SessionEnd"
)

# Install hooks (symlink from Claude hooks dir to repo)
for hook_file in "${!HOOKS[@]}"; do
    hook_name="${HOOKS[$hook_file]}"
    source_path="$SCRIPT_DIR/hooks/$hook_file"
    target_path="$CLAUDE_HOOKS_DIR/$hook_name"

    # Check if hook already exists
    if [[ -e "$target_path" ]]; then
        if [[ -L "$target_path" ]]; then
            # It's a symlink - check if it points to our hook
            if [[ "$(readlink "$target_path")" == "$source_path" ]]; then
                echo "  ✓ $hook_name already installed"
                continue
            else
                echo "  ⚠ $hook_name exists but points elsewhere"
                read -p "    Overwrite? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "    Skipping $hook_name"
                    continue
                fi
                rm "$target_path"
            fi
        else
            # It's a regular file
            echo "  ⚠ $hook_name exists as a regular file"
            read -p "    Backup and replace? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "    Skipping $hook_name"
                continue
            fi
            mv "$target_path" "${target_path}.backup"
            echo "    Backed up to ${target_path}.backup"
        fi
    fi

    # Create symlink
    ln -s "$source_path" "$target_path"
    echo "  ✓ Installed $hook_name"
done

echo ""
echo "Installation complete!"
echo ""
echo "Configuration:"
echo "  Edit $SCRIPT_DIR/config.yaml to:"
echo "  - Disable characters you don't want to hear"
echo "  - Adjust volume and playback settings"
echo "  - Configure lock directory"
echo ""
echo "Uninstall:"
echo "  Run: $SCRIPT_DIR/uninstall.sh"
echo ""
