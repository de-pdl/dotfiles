#!/bin/bash
# ~/.config/scripts/rice_farm/bg_load.sh
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ Error: $1"
    notify-send -u critical "Rice Farm" "$1"
    exit 1
}

# Validate wallpaper directory
[[ -d "$WALLPAPER_DIR" ]] || error_exit "Wallpaper directory not found: $WALLPAPER_DIR"

# Find random wallpaper
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -print0 | shuf -z -n 1 | tr -d '\0')
[[ -z "$WALLPAPER" ]] && error_exit "No wallpaper found in $WALLPAPER_DIR"

WP_NAME=$(basename "$WALLPAPER")
log "🎨 Loading wallpaper: $WP_NAME"

# Set wallpaper
if ! swaymsg output "*" bg "$WALLPAPER" fill 2>/dev/null; then
    error_exit "Failed to set wallpaper with swaymsg"
fi

# Generate colors with matugen
if command -v matugen &> /dev/null; then
    log "🎨 Generating colors with matugen..."
    if matugen image "$WALLPAPER" -m dark; then
        log "✅ Colors generated"
    else
        log "⚠️  matugen failed (non-fatal)"
    fi
else
    log "⚠️  matugen not found, skipping color generation"
fi

# Trigger config reloads
if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then
    touch "$HOME/.config/alacritty/alacritty.toml"
fi

pkill -USR2 waybar 2>/dev/null || true

log "✅ Wallpaper and colors loaded successfully"
notify-send "Rice Farm" "Wallpaper: $WP_NAME" -i dialog-information
