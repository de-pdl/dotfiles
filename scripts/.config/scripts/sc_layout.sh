#!/bin/bash
INTERNAL="eDP"
sleep 1  # Allow monitors to stabilize

# Disable disconnected outputs first
xrandr | grep " disconnected" | awk '{print $1}' | xargs -I {} xrandr --output {} --off

EXTERNALS=($(xrandr | grep " connected" | grep -v "$INTERNAL" | cut -d" " -f1))
COUNT=${#EXTERNALS[@]}
echo "Found $COUNT external monitor(s): ${EXTERNALS[*]}"

if [ "$COUNT" -eq 2 ]; then
    echo "🏠 Home Setup detected (Dual Monitors)"
    xrandr --output "${EXTERNALS[0]}" --primary --auto --pos 0x0 \
           --output "${EXTERNALS[1]}" --auto --right-of "${EXTERNALS[0]}" \
           --output "$INTERNAL" --auto --right-of "${EXTERNALS[1]}"
elif [ "$COUNT" -eq 1 ]; then
    echo "🎓 Uni Setup detected (Single Monitor)"
    xrandr --output "${EXTERNALS[0]}" --auto --pos 0x0 \
           --output "$INTERNAL" --primary --auto --right-of "${EXTERNALS[0]}"
else
    echo "💻 Mobile Setup detected"
    xrandr --output "$INTERNAL" --primary --auto --pos 0x0
fi
