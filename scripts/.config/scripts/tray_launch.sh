#!/bin/bash
# Launch tray apps with staggered delays
# This runs in BACKGROUND so it doesn't block polybar

sleep 2  # Wait for polybar to fully render

# Launch with small delays between each
nm-applet &
sleep 0.3
blueman-applet &
sleep 0.3
pasystray &

disown
