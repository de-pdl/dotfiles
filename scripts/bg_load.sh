#!/bin/bash

# Get random wallpaper
WALLPAPER=$(find "$HOME/Pictures/wallpaper" -type f -print0 | shuf -z -n 1)

if [ -z "$WALLPAPER" ]; then
    echo "Error: No wallpaper found"
    exit 1
fi

echo "🎨 Loading wallpaper: $(basename "$WALLPAPER")"

# Set wallpaper natively using Sway's IPC (fast and zero overhead)
swaymsg output "*" bg "$WALLPAPER" fill 2>/dev/null

# Generate colors (this can take a moment)
echo "🎨 Generating colors with matugen..."
matugen image "$WALLPAPER" 2>/dev/null

# 👉 NEW: Force Alacritty to reload the new colors
touch ~/.config/alacritty/alacritty.toml

# Tell Waybar to hot-reload the CSS
killall -SIGUSR2 waybar

echo "✅ Wallpaper and colors loaded"
