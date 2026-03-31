#!/bin/bash
# ~/.config/scripts/rice_farm/bg_picker.sh
set -euo pipefail

WP_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
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

[[ -d "$WP_DIR" ]] || error_exit "Wallpaper directory not found: $WP_DIR"

# Get list of wallpapers
readarray -t wallpapers < <(find "$WP_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | xargs basename -a | sort)
[[ ${#wallpapers[@]} -eq 0 ]] && error_exit "No wallpapers found"

# Select via Rofi
selected_name=$(printf '%s\n' "${wallpapers[@]}" | rofi -dmenu -p "󰸉 Wallpaper:" -theme-str 'window {width: 40%;}')
[[ -z "$selected_name" ]] && exit 0

WALLPAPER="$WP_DIR/$selected_name"
[[ -f "$WALLPAPER" ]] || error_exit "Wallpaper file not found: $WALLPAPER"

log "Applying wallpaper: $selected_name"

# Apply wallpaper
if ! swaymsg output "*" bg "$WALLPAPER" fill 2>/dev/null; then
    error_exit "Failed to set wallpaper"
fi

# Generate colors
if command -v matugen &> /dev/null; then
    log "Generating colors..."
    if ! matugen image "$WALLPAPER" -m dark; then
        log "⚠️  Color generation failed (non-fatal)"
    fi
fi

# Trigger reloads
[[ -f "$HOME/.config/alacritty/alacritty.toml" ]] && touch "$HOME/.config/alacritty/alacritty.toml"
pkill -USR2 waybar 2>/dev/null || true

log "✅ Wallpaper applied successfully"
notify-send "Rice Farm" "Wallpaper updated: $selected_name" -i dialog-information
