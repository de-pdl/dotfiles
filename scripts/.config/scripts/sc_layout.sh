#!/bin/bash

# Internal display
INTERNAL="eDP"

# Get connected monitors except the internal one
EXTERNAL=$(xrandr | grep " connected" | grep -v "$INTERNAL" | cut -d" " -f1 | head -n1)

if [ -n "$EXTERNAL" ]; then
    # External monitor connected: Set it as primary to the left of laptop
    xrandr \
        --output "$EXTERNAL" --primary --auto --pos 0x0 --rotate normal \
        --output "$INTERNAL" --auto --right-of "$EXTERNAL" --rotate normal
else
    # No external monitor: Reset internal to native resolution and turn off others
    # We use 'x' instead of '*' and ensure no stray characters exist
    xrandr --output "$INTERNAL" --primary --mode 2256x1504 --pos 0x0 --rotate normal
    
    # Optional: Force-disable common external ports to clean up the framebuffer
    xrandr --output DisplayPort-0 --off --output DisplayPort-1 --off --output DisplayPort-2 --off
fi

