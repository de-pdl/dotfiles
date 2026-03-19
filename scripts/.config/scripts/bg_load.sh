#!/bin/bash

# Get random wallpaper
WALLPAPER=$(find "$HOME/Pictures/wallpaper" -type f -print0 | shuf -z -n 1)

if [ -z "$WALLPAPER" ]; then
    echo "Error: No wallpaper found"
    exit 1
fi

echo "🎨 Loading wallpaper: $(basename "$WALLPAPER")"

# Set wallpaper immediately (fast)
feh --bg-max "$WALLPAPER" 2>/dev/null

# Generate colors (this can take a moment)
echo "🎨 Generating colors with matugen..."
matugen image "$WALLPAPER" 2>/dev/null

echo "✅ Wallpaper and colors loaded"
