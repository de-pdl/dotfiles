#!/bin/bash
# ~/.config/scripts/rice_farm/main_rice.sh
set -euo pipefail

SCRIPTS_DIR="$HOME/.config/scripts/rice_farm"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ Error: $1"
    notify-send -u critical "Rice Farm" "$1"
    exit 1
}

validate_script() {
    [[ -f "$1" && -x "$1" ]] || error_exit "Script not found: $1"
}

notify_success() {
    notify-send "Rice Farm" "$1" -i view-refresh
}

choose_matugen_preference() {
    local options="darkness\nlightness\nsaturation\nless-saturation\nvalue\nclosest-to-fallback"
    echo -e "$options" | rofi -dmenu -i -p "󰨇 Color Preference:" -theme-str 'window {width: 20%;}'
}

# ============================================================================
# MENU FUNCTIONS
# ============================================================================

change_wallpaper() {
    log "Opening wallpaper picker..."
    local prefer=$(choose_matugen_preference)
    [[ -z "$prefer" ]] && return 0
    
    validate_script "$SCRIPTS_DIR/bg_picker.sh"
    export MATUGEN_PREFER="$prefer"
    "$SCRIPTS_DIR/bg_picker.sh"
}

change_waybar() {
    log "Opening waybar picker..."
    validate_script "$SCRIPTS_DIR/waybar_picker.sh"
    "$SCRIPTS_DIR/waybar_picker.sh"
}

random_wallpaper() {
    log "Loading random wallpaper..."
    local prefer=$(choose_matugen_preference)
    [[ -z "$prefer" ]] && return 0
    
    export MATUGEN_PREFER="$prefer"
    validate_script "$SCRIPTS_DIR/bg_load.sh"
    "$SCRIPTS_DIR/bg_load.sh"
}

refresh_waybar() {
    log "Refreshing Waybar..."
    pkill -f waybar || true
    sleep 0.3
    PATH="$HOME/.local/bin:$PATH" waybar > /dev/null 2>&1 &
    log "✅ Waybar refreshed"
    notify_success "Waybar Refreshed"
}

reload_sway() {
    log "Reloading Sway configuration..."
    swaymsg reload || error_exit "Failed to reload Sway"
    sleep 1
    
    # Load random wallpaper with default darkness preference
    export MATUGEN_PREFER="darkness"
    validate_script "$SCRIPTS_DIR/bg_load.sh"
    "$SCRIPTS_DIR/bg_load.sh" &
    
    # Refresh waybar
    pkill -f waybar || true
    sleep 0.3
    PATH="$HOME/.local/bin:$PATH" waybar > /dev/null 2>&1 &
    
    # Run setup if it exists
    [[ -f "$HOME/.config/scripts/setup.sh" ]] && "$HOME/.config/scripts/setup.sh" &
    
    log "✅ Sway configuration reloaded"
    notify_success "Sway Config Reloaded"
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_menu() {
    local options="󰸉 Change Wallpaper\n󱁻 Change Waybar\n Random Wallpaper\n󰃢 Refresh Waybar\n󰑐 Reload Sway"
    echo -e "$options" | rofi -dmenu -i -p "󰄼 Rice Management:" -theme-str 'window {width: 30%;}'
}

handle_choice() {
    case "$1" in
        "󰸉 Change Wallpaper")
            change_wallpaper
            ;;
        "󱁻 Change Waybar")
            change_waybar
            ;;
        " Random Wallpaper")
            random_wallpaper
            ;;
        "󰃢 Refresh Waybar")
            refresh_waybar
            ;;
        "󰑐 Reload Sway")
            reload_sway
            ;;
        *)
            log "Unknown choice: $1"
            ;;
    esac
}

# ============================================================================
# ENTRY POINT
# ============================================================================

main() {
    local choice
    choice=$(show_menu)
    
    # Exit if user cancelled
    [[ -z "$choice" ]] && exit 0
    
    handle_choice "$choice"
}

main "$@"
