#!/usr/bin/env bash
# play_sound.sh - Play a Warcraft II sound for the current character
# Usage: play_sound.sh <speech_type> [fallback_speech_type]

set -euo pipefail

# Check if this terminal window has focus - only play if unfocused
# TEMPORARILY DISABLED FOR DEBUGGING - ALWAYS PLAY SOUNDS
# FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "")
#
# # If iTerm2 or Terminal isn't the frontmost app, we can play sound
# SHOULD_PLAY=false
# if [[ "$FRONTMOST" != "iTerm2" && "$FRONTMOST" != "Terminal" ]]; then
#     SHOULD_PLAY=true
# elif [[ "$FRONTMOST" == "iTerm2" ]]; then
#     # iTerm2 is frontmost, check if THIS window is active
#     CURRENT_WINDOW="$ITERM_SESSION_ID"
#     ACTIVE_WINDOW=$(osascript -e 'tell application "iTerm2"
#         try
#             return id of current session of current window
#         end try
#     end tell' 2>/dev/null || echo "")
#
#     if [[ -n "$CURRENT_WINDOW" && "$CURRENT_WINDOW" != "$ACTIVE_WINDOW" ]]; then
#         SHOULD_PLAY=true
#     fi
# elif [[ "$FRONTMOST" == "Terminal" ]]; then
#     # Terminal is frontmost, check if THIS window is active
#     CURRENT_TTY=$(tty 2>/dev/null || echo "")
#     ACTIVE_TTY=$(osascript -e 'tell application "Terminal"
#         try
#             return tty of front window
#         end try
#     end tell' 2>/dev/null || echo "")
#
#     if [[ -n "$CURRENT_TTY" && "$CURRENT_TTY" != "$ACTIVE_TTY" ]]; then
#         SHOULD_PLAY=true
#     fi
# fi
#
# # Exit early if window is focused
# if [[ "$SHOULD_PLAY" != "true" ]]; then
#     exit 0
# fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_ROOT/config.yaml"
LABELS_FILE="$REPO_ROOT/sounds/labels.json"
SOUNDS_DIR="$REPO_ROOT/sounds"

# Check if playback is enabled
PLAYBACK_ENABLED=$(grep -A3 "^playback:" "$CONFIG_FILE" | grep "enabled:" | sed 's/.*: //' | xargs)
if [[ "$PLAYBACK_ENABLED" != "true" ]]; then
    exit 0
fi

# Get volume setting (strip inline comments)
VOLUME=$(grep -A3 "^playback:" "$CONFIG_FILE" | grep "volume:" | sed 's/.*: //' | sed 's/#.*//' | xargs)

# Get current character from environment variable
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    echo "ERROR: WC2_CHARACTER environment variable not set" >&2
    exit 1
fi

# Get speech type arguments (can provide multiple as fallbacks)
SPEECH_TYPES=("$@")

if [[ ${#SPEECH_TYPES[@]} -eq 0 ]]; then
    echo "ERROR: Speech type not provided" >&2
    echo "Usage: $0 <speech_type> [fallback1] [fallback2] ..." >&2
    exit 1
fi

# Function to find sound file for character and speech type
find_sound() {
    local character="$1"
    local speech_type="$2"

    # Query labels.json for matching sound and randomly pick one
    local sound_file=$(jq -r --arg char "$character" --arg speech "$speech_type" --argjson seed "$RANDOM" '
        [.sounds[]
        | select(
            .category == "unit"
            and .["Unit Type"] != null
            and (.["Unit Type"] | tostring | split(",") | map(gsub("^[[:space:]]+|[[:space:]]+$"; "")) | index($char))
            and (.["Speech Type"] == $speech)
        )
        | .file] | if length > 0 then (. | to_entries | map(.value) | .[($seed % length)]) else empty end
    ' "$LABELS_FILE")

    if [[ -n "$sound_file" ]]; then
        echo "$sound_file"
        return 0
    fi
    return 1
}

# Try to find sound, trying each speech type in order
SOUND_FILE=""
for speech_type in "${SPEECH_TYPES[@]}"; do
    if SOUND_FILE=$(find_sound "$WC2_CHARACTER" "$speech_type"); then
        break
    fi
done

if [[ -z "$SOUND_FILE" ]]; then
    # Silently fail - character doesn't have any of these speech types
    exit 0
fi

# Extract just the filename from the path in labels.json
SOUND_FILENAME=$(basename "$SOUND_FILE")
SOUND_PATH="$SOUNDS_DIR/$SOUND_FILENAME"

# Check if sound file exists
if [[ ! -f "$SOUND_PATH" ]]; then
    echo "ERROR: Sound file not found: $SOUND_PATH" >&2
    exit 1
fi

# DEBUG: Log what we're about to play
echo "Playing: $SOUND_PATH for character $WC2_CHARACTER" >> /tmp/wc2-sound-plays.log

# Play the sound (macOS uses afplay)
if command -v afplay &> /dev/null; then
    # afplay doesn't have a native volume control, use osascript
    if [[ "$VOLUME" != "1.0" ]]; then
        # Get current volume, play sound, restore volume
        current_volume=$(osascript -e 'output volume of (get volume settings)')
        target_volume=$(echo "$VOLUME * 100" | bc | cut -d. -f1)
        osascript -e "set volume output volume $target_volume" 2>/dev/null
        afplay "$SOUND_PATH"
        osascript -e "set volume output volume $current_volume" 2>/dev/null
    else
        afplay "$SOUND_PATH"
    fi
elif command -v aplay &> /dev/null; then
    # Linux ALSA
    aplay -q "$SOUND_PATH" &
elif command -v paplay &> /dev/null; then
    # Linux PulseAudio
    paplay "$SOUND_PATH" &
else
    echo "ERROR: No audio player found (afplay, aplay, or paplay)" >&2
    exit 1
fi

exit 0
