#!/bin/bash

# Define your display names
INTERNAL="eDP"
# Get all connected monitors except the internal one, stored in an array
EXTERNALS=($(xrandr | grep " connected" | grep -v "$INTERNAL" | cut -d" " -f1))
COUNT=${#EXTERNALS[@]}

echo "Found $COUNT external monitor(s): ${EXTERNALS[*]}"

# --- Profile Logic ---

if [ "$COUNT" -eq 2 ]; then
    # HOME SETUP: Dual monitors + Laptop (Optional)
    echo "🏠 Home Setup detected (Dual Monitors)"
    
    # Example: [Monitor 1] [Monitor 2] [Laptop]
    xrandr --output "${EXTERNALS[0]}" --primary --auto --pos 0x0 --rotate normal \
           --output "${EXTERNALS[1]}" --auto --right-of "${EXTERNALS[0]}" \
           --output "$INTERNAL" --auto --right-of "${EXTERNALS[1]}"

elif [ "$COUNT" -eq 1 ]; then
    # UNI SETUP: Single external monitor + Laptop
    echo "🎓 Uni Setup detected (Single Monitor)"
    
    xrandr --output "${EXTERNALS[0]}" --primary --auto --pos 0x0 \
           --output "$INTERNAL" --auto --right-of "${EXTERNALS[0]}"

else
    # MOBILE SETUP: Laptop only
    echo "💻 Mobile Setup detected"
    
    xrandr --output "$INTERNAL" --primary --mode 2256x1504 --pos 0x0
    
    # Turn off all disconnected/ghost outputs
    xrandr | grep " disconnected" | awk '{print $1}' | xargs -I {} xrandr --output {} --off
fi
