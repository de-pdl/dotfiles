#!/bin/bash

if ! pgrep -x "pomatez" > /dev/null; then
    echo "{\"text\": \"⏸\", \"class\": \"off\", \"tooltip\": \"Pomatez not running\"}"
    exit 0
fi

# Get window title
WINDOW_TITLE=$(xdotool search --name "pomatez" getwindowname %@ 2>/dev/null | head -1)

if [ -z "$WINDOW_TITLE" ]; then
    echo "{\"text\": \"⏸\", \"class\": \"off\", \"tooltip\": \"Pomatez window not found\"}"
    exit 0
fi

# Extract timer (XX:XX format)
TIMER=$(echo "$WINDOW_TITLE" | grep -oP '\d+:\d+' | head -1)

if [ -z "$TIMER" ]; then
    TIMER="--:--"
fi

# Determine work or break from tooltip
if echo "$WINDOW_TITLE" | grep -qi "break"; then
    CLASS="break"
else
    CLASS="work"
fi

echo "{\"text\": \"⏱ $TIMER\", \"class\": \"$CLASS\", \"tooltip\": \"$WINDOW_TITLE\"}"
