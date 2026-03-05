#!/usr/bin/env sh

# ==========================================================
# TERMINATE IS ALREADY IN THE STARTUP SCRIPT 
# Terminate already running bar instances
# killall -q polybar
# Wait until the processes have been shut down
#while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
# ==========================================================

PRIMARY_DISPLAY=$(xrandr --query | grep " primary" | cut -d" " -f1)

# for multimonitor
if type "xrandr"; then
	for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    if [ "$m" == "$PRIMARY_DISPLAY" ]; then
        # Launch the bar that HAS the tray
        MONITOR=$m polybar --reload primary & disown
    else
        # Launch the bar WITHOUT the tray on everything else
        MONITOR=$m polybar --reload secondary & disown
    fi
	done
fi
