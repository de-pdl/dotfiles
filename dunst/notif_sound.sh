#!/bin/sh
SOUND_DIR="/usr/share/sounds/freedesktop/stereo"
URGENCY="${DUNST_URGENCY:-$1}"
# Convert to lowercase
URGENCY=$(echo "$URGENCY" | tr '[:upper:]' '[:lower:]')

case "$URGENCY" in
    critical)
        paplay "$SOUND_DIR/alarm-clock-elapsed.oga" 2>/dev/null &
        ;;
    normal)
        paplay "$SOUND_DIR/message-new-instant.oga" 2>/dev/null &
        ;;
    low)
        paplay "$SOUND_DIR/bell.oga" 2>/dev/null &
        ;;
    *)
        paplay "$SOUND_DIR/message.oga" 2>/dev/null &
        ;;
esac
