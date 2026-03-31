#!/bin/bash
# ~/.config/scripts/rice_farm/main_rice.sh
set -euo pipefail

SCRIPTS_DIR="$HOME/.config/scripts/rice_farm"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "❌ Error: $1"
    notify-send -u critical "Rice Farm" "$1"
    exit 1
}

# Validate script exists
validate_script() {
    [[ -f "$1" && -x "$1" ]] || error_exit "Script not found: $1"
}

# Main menu options
options="󰸉 Change Wallpaper\n󱁻 Change Waybar\n Random Wallpaper\n󰃢 Refresh Waybar\n󰑐 Reload Sway"

choice=$(echo -e "$options" | rofi -dmenu -i -p "󰄼 Rice Management:" -theme-str 'window {width: 30%;}')
[[ -z "$choice" ]] && exit 0

case "$choice" in
    "󰸉 Change Wallpaper")
        validate_script "$SCRIPTS_DIR/bg_picker.sh"
        "$SCRIPTS_DIR/bg_picker.sh"
        ;;
    "󱁻 Change Waybar")
        validate_script "$SCRIPTS_DIR/waybar_picker.sh"
        "$SCRIPTS_DIR/waybar_picker.sh"
        ;;
    " Random Wallpaper")
        validate_script "$SCRIPTS_DIR/bg_load.sh"
        "$SCRIPTS_DIR/bg_load.sh"
        ;;
    "󰃢 Refresh Waybar")
        log "Refreshing Waybar..."
        pkill -f waybar || true
        sleep 0.3
        waybar > /dev/null 2>&1 &
        log "✅ Waybar refreshed"
        notify-send "Rice Farm" "Waybar Refreshed" -i view-refresh
        ;;
    "󰑐 Reload Sway")
        log "Reloading Sway configuration..."
        swaymsg reload || error_exit "Failed to reload Sway"
        sleep 0.5
        [[ -f "$HOME/.config/scripts/setup.sh" ]] && "$HOME/.config/scripts/setup.sh" &
        log "✅ Sway configuration reloaded"
        notify-send "Rice Farm" "Sway Config Reloaded" -i view-refresh
        ;;
esac
