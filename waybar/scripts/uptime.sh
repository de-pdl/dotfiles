#!/bin/bash
# ~/.config/waybar/scripts/uptime.sh

uptime_seconds=$(cut -d. -f1 /proc/uptime)

hours=$((uptime_seconds / 3600))
minutes=$(( (uptime_seconds % 3600) / 60 ))

if [ $hours -eq 0 ]; then
    echo "${minutes}m"
else
    echo "${hours}h ${minutes}m"
fi
