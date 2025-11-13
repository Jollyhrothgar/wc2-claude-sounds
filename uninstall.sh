#!/usr/bin/env bash
# uninstall.sh - Uninstall Warcraft II Claude Code sound hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="${HOME}/.claude/settings.json"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"

echo "Uninstalling Warcraft II Claude Code sound hooks..."

# Check if settings.json exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "  ⚠ $SETTINGS_FILE not found, nothing to uninstall"
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed"
    echo "Install with: brew install jq"
    exit 1
fi

# Backup settings
cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
echo "  ✓ Backed up settings to ${SETTINGS_FILE}.backup"

# Remove WC2 hooks from settings
NEW_SETTINGS=$(cat "$SETTINGS_FILE" | jq --arg script_dir "$SCRIPT_DIR" '
  # Remove SessionStart if it matches our hook
  if .hooks.SessionStart then
    .hooks.SessionStart = [.hooks.SessionStart[] | select(.hooks[0].command != ($script_dir + "/hooks/session-start.sh"))]
    | if .hooks.SessionStart == [] then del(.hooks.SessionStart) else . end
  else . end |

  # Remove UserPromptSubmit if it matches our hook
  if .hooks.UserPromptSubmit then
    .hooks.UserPromptSubmit = [.hooks.UserPromptSubmit[] | select(.hooks[0].command != ($script_dir + "/hooks/user-prompt-submit.sh"))]
    | if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end
  else . end |

  # Remove Stop if it matches our hook
  if .hooks.Stop then
    .hooks.Stop = [.hooks.Stop[] | select(.hooks[0].command != ($script_dir + "/hooks/stop.sh"))]
    | if .hooks.Stop == [] then del(.hooks.Stop) else . end
  else . end |

  # Remove our notification hook (but keep others)
  if .hooks.Notification then
    .hooks.Notification[0].hooks = [.hooks.Notification[0].hooks[] | select(.command != ($script_dir + "/hooks/notification.sh"))]
    | if .hooks.Notification[0].hooks == [] then del(.hooks.Notification) else . end
  else . end |

  # Remove SessionEnd if it matches our hook
  if .hooks.SessionEnd then
    .hooks.SessionEnd = [.hooks.SessionEnd[] | select(.hooks[0].command != ($script_dir + "/hooks/session-end.sh"))]
    | if .hooks.SessionEnd == [] then del(.hooks.SessionEnd) else . end
  else . end
')

# Write new settings
echo "$NEW_SETTINGS" > "$SETTINGS_FILE"
echo "  ✓ Removed WC2 hooks from $SETTINGS_FILE"

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

# Clean up old symlinks if they exist
CLAUDE_HOOKS_DIR="${HOME}/.config/claude/hooks"
if [[ -d "$CLAUDE_HOOKS_DIR" ]]; then
    for hook in SessionStart UserPromptSubmit Stop Notification SessionEnd; do
        if [[ -L "$CLAUDE_HOOKS_DIR/$hook" ]]; then
            link_target=$(readlink "$CLAUDE_HOOKS_DIR/$hook")
            if [[ "$link_target" == "$SCRIPT_DIR"/hooks/* ]]; then
                rm "$CLAUDE_HOOKS_DIR/$hook"
                echo "  ✓ Removed old symlink: $hook"
            fi
        fi
    done
fi

echo ""
echo "Uninstall complete!"
echo ""
echo "⚠️  IMPORTANT: Restart Claude Code for changes to take effect"
echo ""
