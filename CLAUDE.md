# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This project adds Warcraft II unit voices to Claude Code sessions via hooks. Each terminal session gets a random WC2 character that persists throughout, playing sounds at key workflow events.

## Key Architecture

### Character Selection System (`scripts/select_character.sh`)

Character selection happens at shell startup via `init.sh`:

1. **Character Pool**: Reads all unit types from `sounds/labels.json` (filtering `category: "unit"` with non-null faction and Unit Type)
2. **Filtering**: Removes disabled characters from `config.yaml` `disabled_characters` list
3. **Lock System**: Checks `/tmp/claude-wc2-locks/` for characters in use by other sessions (prevents duplicates)
4. **Stale Lock Cleanup**: Removes locks for dead PIDs or locks older than `stale_lock_hours`
5. **Selection**: Randomly picks from available pool, creates lock file with shell PID
6. **Environment Variable**: Exports `WC2_CHARACTER` for session

**Important**: The SessionStart hook uses the character already selected by the shell (`WC2_CHARACTER` env var) instead of selecting a new one. This ensures character consistency throughout the session.

### Sound Playback System (`scripts/play_sound.sh`)

Sound playback uses `WC2_CHARACTER` environment variable and speech type:

1. **Character Lookup**: Queries `sounds/labels.json` for sounds matching character + speech type
2. **Random Selection**: If multiple sounds match, randomly picks one
3. **Fallback Support**: Can accept multiple speech types as fallbacks (e.g., "Acknowledge" → "Ready")
4. **Volume Control**: Reads volume from `config.yaml`, uses OS volume API on macOS
5. **Platform Detection**: Uses `afplay` (macOS), `aplay` (Linux ALSA), or `paplay` (PulseAudio)
6. **Synchronous Playback**: Plays sound synchronously to prevent overlapping

### Hook Event Mapping

Claude Code hooks → WC2 speech types (defined in `config.yaml:events`):

- **SessionStart** → "Greeting", "Annoyed", "Ready", "Silly" (session-start.sh) - plays when session starts
- **UserPromptSubmit** → "Acknowledge" (user-prompt-submit.sh) - plays when user submits a message
- **Stop** → "Complete", "Annoyed", "Ready" (stop.sh) - plays when Claude finishes responding
- **Notification** → "Alert", "Annoyed", "Annoyed" (notification.sh) - plays when Claude needs attention
- **SessionEnd** → "Death", "Annoyed", "Acknowledge" (session-end.sh) - plays death sound and cleans up session

**Key Change**: Hooks now use response-level events (UserPromptSubmit/Stop) instead of tool-level events (PreToolUse/PostToolUse), eliminating multiple simultaneous sounds when tools run in parallel.

### Session Persistence

Character assignment persists via two mechanisms:

1. **Shell Sessions**: `init.sh` sets `WC2_CHARACTER` environment variable (inherited by subshells)
2. **Claude Code Sessions**: `session-start.sh` creates `/tmp/wc2-character-$PPID` file with selected character

The PPID (parent process ID, i.e., Claude Code process) serves as session identifier.

**Character Selection Priority** (all hooks follow this):
1. Check `WC2_CHARACTER` environment variable (set by shell's `init.sh`)
2. Check `/tmp/wc2-character-$PPID` session file
3. Only as last resort, call `select_character.sh` to pick a new character

## Data Files

### `sounds/labels.json`

Metadata for 218 WAV files with structure:
```json
{
  "sounds": [{
    "file": "path/to/sound.wav",
    "category": "unit" | "building" | "spell" | "ambience",
    "faction": "Alliance" | "Horde" | null,
    "Unit Type": "Peasant, Knight" (comma-separated for shared sounds),
    "Speech Type": "Greeting" | "Acknowledge" | "Ready" | "Alert" | "Annoyed" | "Complete"
  }]
}
```

Some sounds are shared across multiple units (e.g., "Peasant, Peon" for worker sounds).

### `config.yaml`

User configuration:
- `disabled_characters`: List of character names to exclude from random selection
- `events`: Maps Claude events to speech types (with optional fallbacks)
- `playback.volume`: 0.0-1.0 volume multiplier
- `playback.enabled`: Master enable/disable
- `playback.min_duration_for_complete`: Minimum seconds for PostToolUse sound
- `locking.enabled`: Enable/disable multi-window lock system
- `locking.lock_dir`: Lock file directory
- `locking.stale_lock_hours`: Age threshold for stale lock cleanup

**Config Parsing Pattern**: Scripts use simple bash commands to parse YAML:
```bash
# Extract value on same line as key, strip comments
VALUE=$(grep "key:" config.yaml | sed 's/.*key: *//' | sed 's/#.*//' | xargs)
```
This avoids pulling in comment lines that come after the key.

## Common Tasks

### Install hooks
```bash
./install.sh  # Updates ~/.claude/settings.json, backs up to settings.json.backup
```

### Uninstall hooks
```bash
./uninstall.sh  # Removes hooks from settings.json
```

### Test character selection
```bash
./scripts/select_character.sh  # Prints selected character name
```

### Test sound playback
```bash
export WC2_CHARACTER="Peasant"  # Set character manually
./scripts/play_sound.sh "Greeting"  # Play greeting sound
./scripts/play_sound.sh "Acknowledge" "Ready"  # With fallback
```

### Debug hooks
```bash
tail -f /tmp/wc2-hook-calls.log  # Hook execution log
tail -f /tmp/wc2-sound-plays.log  # Sound playback log
```

### Check lock status
```bash
ls -la /tmp/claude-wc2-locks/  # View active character locks
cat /tmp/claude-wc2-locks/Knight.lock  # Show PID holding lock
```

### Clean stale locks manually
```bash
rm -rf /tmp/claude-wc2-locks/*
```

## Installation Flow

1. `install.sh` registers hooks in `~/.claude/settings.json` using `jq`
2. User adds `source ~/workspace/wc2-claude-sounds/init.sh` to shell startup
3. On new shell, `init.sh` calls `select_character.sh` and exports `WC2_CHARACTER`
4. On Claude Code startup, `session-start.sh` hook fires and plays greeting
5. During Claude operations, other hooks fire and play corresponding sounds

## Dependencies

- `jq` - JSON parsing for labels.json queries and settings.json manipulation
- `bash` - All scripts require bash (uses array features)
- Audio player: `afplay` (macOS), `aplay` (Linux), or `paplay` (PulseAudio)
- `osascript` - macOS only, for volume control

## Important Notes

- **Restart Required**: Claude Code must be restarted after running `install.sh` or `uninstall.sh` for hook changes to take effect
- **Shell Init**: Character selection happens at shell startup, not Claude Code startup
- **Lock Files**: Contain shell PID ($$), not Claude Code PID ($PPID)
- **Session Files**: Use Claude Code PID ($PPID) as identifier
- **Volume Control**: macOS `afplay` volume control temporarily changes system volume
- **Synchronous Playback**: Sounds play synchronously to prevent overlapping (intentional)
- **Focus Detection**: play_sound.sh has commented-out code for window focus detection (disabled for debugging)
