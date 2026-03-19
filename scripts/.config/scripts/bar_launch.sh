#!/usr/bin/env sh
# Launch polybar instances for all connected monitors
killall -q polybar 2>/dev/null
sleep 0.3
# Check dependencies
if ! command -v xrandr &>/dev/null; then
    echo "Error: xrandr not found" >&2
    exit 1
fi

if ! command -v polybar &>/dev/null; then
    echo "Error: polybar not found" >&2
    exit 1
fi

# Get primary display
PRIMARY_DISPLAY=$(xrandr --query | grep " primary" | cut -d" " -f1)

if [ -z "$PRIMARY_DISPLAY" ]; then
    echo "Error: No primary display found" >&2
    exit 1
fi

echo "Primary display: $PRIMARY_DISPLAY"

# Launch bars for all connected monitors
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    if [ "$m" = "$PRIMARY_DISPLAY" ]; then
        echo "Launching primary bar on $m (with tray)"
        BAR_NAME="primary"
    else
        echo "Launching secondary bar on $m"
        BAR_NAME="secondary"
    fi
    
    MONITOR=$m polybar --reload "$BAR_NAME" 2>/dev/null &
    sleep 0.2  # Small delay between launches
    disown
done

echo "Polybar instances launched"
disown
