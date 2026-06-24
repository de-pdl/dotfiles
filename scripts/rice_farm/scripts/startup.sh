#!/bin/bash
# Variables - Updated for flat structure
username="ayush"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean Slate (Wayland tools only)
APPS="gammastep waybar kanshi"
killall -q $APPS 2>/dev/null

# Wait for apps to die
while pgrep -u $UID -x "$(echo $APPS | tr ' ' '|')" >/dev/null; do
    sleep 0.1
done


log ("death?")

# --- Core Services ---
# 1. Monitor Layout (Kanshi is the master now)
kanshi &
sleep 1  # Give kanshi time to start and read current state

# Force kanshi to reload/match profile
pkill -USR1 kanshi 2>/dev/null || true

# 2. Notification agent
# dunst & (in swayrc)

# 3. Screen color temperature (Wayland native)
gammastep &

# 4. Background & Colors
$script_dir/bg_load.sh &

waybar &

disown
