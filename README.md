# Warcraft II Claude Code Sound Hooks

Bring Warcraft II: Tides of Darkness unit voices to your Claude Code sessions! Each terminal gets a randomly assigned character that persists for the session, with sounds playing at key moments in your workflow.

## Features

- **Random Character Assignment**: Each Claude Code session gets a unique Warcraft II character (Peasant, Knight, Grunt, Mage, etc.)
- **Session Persistence**: Character stays consistent throughout the session
- **Multi-Window Lock System**: Different terminal windows get different characters (no duplicates)
- **Event-Based Sounds**:
  - **Session Start**: Greeting sound (e.g., "Yes, m'lord?")
  - **User Input**: Acknowledgment when you submit a message (e.g., "Yes?", "Okay")
  - **Response Complete**: Completion when Claude finishes (e.g., "Job's done!", "Complete!")
  - **Needs Attention**: Alert sound (e.g., "What?", "Hmm?")
  - **Session Exit**: Death sound when exiting Claude Code
- **Configurable**: Disable specific characters, adjust volume, set minimum task duration for completion sounds
- **Automatic Cleanup**: Stale locks and dead processes are cleaned up automatically

## Installation

1. **Register hooks**:
```bash
cd wc2-claude-sounds
./install.sh
```

2. **Add to shell startup** (`~/.zshrc` or `~/.bashrc`):
```bash
# Warcraft II Claude Code sounds
source wc2-claude-sounds/init.sh
```

3. **Reload shell**:
```bash
exec zsh  # or exec bash
```

This selects a random WC2 character for each terminal session and registers hooks in `~/.claude/settings.json`.

## Configuration

Edit `config.yaml` to customize:

### Disable Characters

```yaml
disabled_characters:
  - Ship  # Generic ship sounds
  - Gnomish Submarine  # Uncomment any character to disable
  # - Peasant
  # - Knight
```

### Adjust Volume

```yaml
playback:
  volume: 0.8  # 0.0 to 1.0
  enabled: true
```

### Minimum Duration for Complete Sound

Only play completion sounds for tasks that take longer than this threshold:

```yaml
playback:
  min_duration_for_complete: 5.0  # seconds
```

### Lock Directory

```yaml
locking:
  enabled: true
  lock_dir: /tmp/claude-wc2-locks
  stale_lock_hours: 24  # Clean up locks older than this
```

## Available Characters

### Alliance
- Peasant
- Footman
- Knight
- Elven Archer
- Mage
- Paladin
- Dwarven Demolition Squad
- Gryphon Rider
- Gnomish Flying Machine
- Gnomish Submarine

### Horde
- Peon
- Grunt
- Ogre
- Troll Axe Thrower
- Death Knight
- Goblin Demolition Crew
- Dragon
- Goblin Zeppelin

### Neutral
- Ships (generic, disabled by default)

## How It Works

### Character Selection

1. On session start, `select_character.sh` runs
2. Reads all available characters from `sounds/labels.json`
3. Filters out disabled characters from `config.yaml`
4. Checks lock directory for characters in use by other sessions
5. Randomly picks from remaining available characters
6. Creates lock file with current shell PID
7. Exports `WC2_CHARACTER` environment variable

### Sound Playback

1. Hook scripts call `play_sound.sh` with speech type (e.g., "Greeting", "Acknowledge")
2. Script queries `sounds/labels.json` for sound files matching current character + speech type
3. If multiple sounds exist, randomly picks one
4. Plays sound using `afplay` (macOS), `aplay` (Linux), or `paplay` (PulseAudio)

### Lock Management

- Lock files stored in `/tmp/claude-wc2-locks/` (configurable)
- Each lock file contains the shell PID
- On session end, lock is removed
- Stale locks (dead PIDs or >24h old) cleaned up automatically on next session start

## Hook Events

| Claude Event | Speech Type | Example Sounds |
|-------------|-------------|----------------|
| SessionStart | Greeting / Annoyed / Ready / Silly | "Yes, m'lord?", "Ready to serve!", "Zug zug" |
| UserPromptSubmit | Acknowledge | "Yes?", "Okay", "Huh?" |
| Stop | Complete / Annoyed / Ready | "Job's done!", "Complete!", "Done!" |
| Notification | Alert / Annoyed | "What?", "Hmm?", "Stop poking me!" |
| SessionEnd | Death / Annoyed / Acknowledge | Death screams, groans |

## File Structure

```
wc2-claude-sounds/
├── config.yaml              # User configuration
├── install.sh               # Installation script
├── uninstall.sh            # Uninstallation script
├── README.md               # This file
├── sounds/
│   ├── labels.json         # Sound file metadata
│   └── *.wav               # 218 labeled WAV files
├── scripts/
│   ├── select_character.sh      # Character selection logic
│   └── play_sound.sh            # Sound playback logic
└── hooks/
    ├── session-start.sh         # SessionStart hook
    ├── user-prompt-submit.sh    # UserPromptSubmit hook
    ├── stop.sh                  # Stop hook
    ├── notification.sh          # Notification hook
    └── session-end.sh           # SessionEnd hook
```

## Uninstallation

```bash
cd ~/workspace/wc2-claude-sounds
./uninstall.sh
```

This removes the hooks from `~/.claude/settings.json` and optionally cleans up the lock directory.

**Important**: Restart Claude Code after uninstallation for changes to take effect.

## Troubleshooting

### No sounds playing

1. Check that hooks are installed: `ls -la ~/.config/claude/hooks/`
2. Verify `WC2_CHARACTER` is set: `echo $WC2_CHARACTER`
3. Check config: `enabled: true` in `config.yaml`
4. Test manually: `./scripts/play_sound.sh Greeting`

### Same character in multiple windows

- Lock system may be disabled in `config.yaml`
- Check for stale locks: `ls -la /tmp/claude-wc2-locks/`
- Manually clean up: `rm -rf /tmp/claude-wc2-locks/*`

### "No available characters" error

- All characters are either disabled in `config.yaml` or locked by other sessions
- Disable locking temporarily or reduce disabled character list

### Volume too loud/quiet

- Adjust `volume` in `config.yaml` (0.0 to 1.0)
- Note: macOS `afplay` volume control changes system volume temporarily

### Always getting the same character (Peasant)

- This was caused by shell compatibility issues with `${BASH_SOURCE[0]}` in zsh
- Fixed in latest version of `init.sh` (supports both bash and zsh)
- If you updated `init.sh`, restart your shell: `exec zsh` or `exec bash`

## Credits

- Warcraft II: Tides of Darkness © Blizzard Entertainment
- Sound extraction and labeling by Mike
- Extracted from original game files using custom tooling

## License

This is a personal project for enhancing development workflow. Game assets remain property of Blizzard Entertainment.
