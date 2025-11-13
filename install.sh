#!/usr/bin/env bash
# install.sh - Install Warcraft II Claude Code sound hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="${HOME}/.claude/settings.json"

echo "Installing Warcraft II Claude Code sound hooks..."

# Check if settings.json exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "ERROR: $SETTINGS_FILE not found"
    echo "Please run Claude Code at least once to create the settings file"
    exit 1
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

# Read current settings
CURRENT_SETTINGS=$(cat "$SETTINGS_FILE")

# Add WC2 hooks to settings (preserving existing hooks)
NEW_SETTINGS=$(echo "$CURRENT_SETTINGS" | jq --arg script_dir "$SCRIPT_DIR" '
  # Initialize hooks object if it doesn'\''t exist
  .hooks //= {} |

  # SessionStart
  .hooks.SessionStart = [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": ($script_dir + "/hooks/session-start.sh")
    }]
  }] |

  # UserPromptSubmit
  .hooks.UserPromptSubmit = [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": ($script_dir + "/hooks/user-prompt-submit.sh")
    }]
  }] |

  # Stop
  .hooks.Stop = [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": ($script_dir + "/hooks/stop.sh")
    }]
  }] |

  # Notification - append to existing hooks
  if .hooks.Notification then
    .hooks.Notification[0].hooks += [{
      "type": "command",
      "command": ($script_dir + "/hooks/notification.sh")
    }]
  else
    .hooks.Notification = [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": ($script_dir + "/hooks/notification.sh")
      }]
    }]
  end |

  # SessionEnd
  .hooks.SessionEnd = [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": ($script_dir + "/hooks/session-end.sh")
    }]
  }]
')

# Write new settings
echo "$NEW_SETTINGS" > "$SETTINGS_FILE"
echo "  ✓ Updated $SETTINGS_FILE with WC2 hooks"

echo ""
echo "Installation complete!"
echo ""
echo "⚠️  IMPORTANT: Restart Claude Code for hooks to take effect"
echo "   (Claude captures hooks at startup)"
echo ""
echo "Configuration:"
echo "  Edit $SCRIPT_DIR/config.yaml to:"
echo "  - Disable characters you don't want to hear"
echo "  - Adjust volume and playback settings"
echo "  - Configure lock directory"
echo ""
echo "Verify installation:"
echo "  Run /hooks in Claude Code to see registered hooks"
echo ""
echo "Uninstall:"
echo "  Run: $SCRIPT_DIR/uninstall.sh"
echo ""
