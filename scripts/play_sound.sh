#!/usr/bin/env bash
# play_sound.sh - Play a Warcraft II sound for the current character
# Usage: play_sound.sh <speech_type> [fallback_speech_type]

set -euo pipefail

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

# Get volume setting
VOLUME=$(grep -A3 "^playback:" "$CONFIG_FILE" | grep "volume:" | sed 's/.*: //' | xargs)

# Get current character from environment variable
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    echo "ERROR: WC2_CHARACTER environment variable not set" >&2
    exit 1
fi

# Get speech type argument
SPEECH_TYPE="${1:-}"
FALLBACK_SPEECH_TYPE="${2:-}"

if [[ -z "$SPEECH_TYPE" ]]; then
    echo "ERROR: Speech type not provided" >&2
    echo "Usage: $0 <speech_type> [fallback_speech_type]" >&2
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

# Try to find sound with primary speech type
SOUND_FILE=""
if SOUND_FILE=$(find_sound "$WC2_CHARACTER" "$SPEECH_TYPE"); then
    : # Found it
elif [[ -n "$FALLBACK_SPEECH_TYPE" ]]; then
    # Try fallback speech type
    if SOUND_FILE=$(find_sound "$WC2_CHARACTER" "$FALLBACK_SPEECH_TYPE"); then
        : # Found with fallback
    fi
fi

if [[ -z "$SOUND_FILE" ]]; then
    # Silently fail - character might not have this speech type
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
        afplay "$SOUND_PATH" &
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
