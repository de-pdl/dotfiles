#!/bin/bash
set -euo pipefail

SCRIPTS_DIR="$HOME/.config/scripts/rice_farm"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"
mkdir -p "$(dirname "$LOG_FILE")"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ Error: $1"
    notify-send -u critical "Rice Farm" "$1" 2>/dev/null || true
    exit 1
}

validate_script() {
    [[ -f "$1" && -x "$1" ]] || error_exit "Script not found: $1"
}

notify_success() {
    notify-send "Rice Farm" "$1" -i view-refresh 2>/dev/null || true
}

check_dependencies() {
    local deps=("rofi" "notify-send" "swaymsg" "waybar")
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || error_exit "$dep not installed"
    done
}

choose_matugen_preference() {
    local options="darkness\nlightness\nsaturation\nless-saturation\nvalue\nclosest-to-fallback"
    echo -e "$options" | rofi -dmenu -i -p "󰨇 Color Preference:" -theme-str 'window {width: 20%;}'
}

restart_waybar() {
    log "Restarting Waybar..."
    pkill -f waybar || true
    sleep 0.3
    PATH="$HOME/.local/bin:$PATH" waybar > /dev/null 2>&1 &
}

# ============================================================================
# WALLPAPER FUNCTIONS
# ============================================================================
get_wallpaper_files() {
    local wallpaper_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
    [[ ! -d "$wallpaper_dir" ]] && error_exit "Wallpaper directory not found: $wallpaper_dir"
    
    find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -print0 | sort -z
}


change_wallpaper() {
    log "Opening wallpaper picker..."

    local prefer
    prefer=$(choose_matugen_preference)
    [[ -z "$prefer" ]] && return 0

    validate_script "$SCRIPTS_DIR/bg_load.sh"

    local wallpaper_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
    [[ ! -d "$wallpaper_dir" ]] && error_exit "Wallpaper directory not found: $wallpaper_dir"

    local icon_list=""
    while IFS= read -r filepath; do
        icon_list+="$(basename "$filepath")\0icon\x1f${filepath}\n"
    done < <(
        find "$wallpaper_dir" -maxdepth 1 -type f \
            -iregex '.*\.\(jpg\|jpeg\|png\|avif\|webp\)$' | sort
    )

    [[ -z "$icon_list" ]] && error_exit "No wallpapers found in: $wallpaper_dir"

    local selected
    selected=$(printf '%b' "$icon_list" | \
        rofi -dmenu -i \
             -show-icons \
             -theme ~/.config/rofi/gallery.rasi)

    [[ -z "$selected" ]] && return 0

    local full_path="$wallpaper_dir/$selected"
    [[ ! -f "$full_path" ]] && error_exit "Wallpaper not found: $full_path"

    log "🎨 Loading wallpaper: $selected"
    "$SCRIPTS_DIR/bg_load.sh" "$full_path" "$prefer"
    notify_success "Wallpaper changed: $selected"
}  

random_wallpaper() {
    log "Loading random wallpaper..."
    local prefer=$(choose_matugen_preference)
    [[ -z "$prefer" ]] && return 0
    
    validate_script "$SCRIPTS_DIR/bg_load.sh"
    export MATUGEN_PREFER="$prefer"
    "$SCRIPTS_DIR/bg_load.sh"
    notify_success "Random wallpaper loaded"
}

# ============================================================================
# OTHER MENU FUNCTIONS
# ============================================================================
change_waybar() {
    log "Opening waybar picker..."
    validate_script "$SCRIPTS_DIR/waybar_picker.sh"
    "$SCRIPTS_DIR/waybar_picker.sh"
}

refresh_waybar() {
    log "Refreshing Waybar..."
    restart_waybar
    log "✅ Waybar refreshed"
    notify_success "Waybar Refreshed"
}

reload_sway() {
    log "Reloading Sway configuration..."
    swaymsg reload || error_exit "Failed to reload Sway"
    sleep 1
    
    export MATUGEN_PREFER="darkness"
    validate_script "$SCRIPTS_DIR/bg_load.sh"
    "$SCRIPTS_DIR/bg_load.sh" &
    
    restart_waybar
    
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
        "󰸉 Change Wallpaper") change_wallpaper ;;
        "󱁻 Change Waybar") change_waybar ;;
        " Random Wallpaper") random_wallpaper ;;
        "󰃢 Refresh Waybar") refresh_waybar ;;
        "󰑐 Reload Sway") reload_sway ;;
        *) log "Unknown choice: $1" ;;
    esac
}

# ============================================================================
# ENTRY POINT
# ============================================================================
main() {
    check_dependencies
    local choice
    choice=$(show_menu)
    [[ -z "$choice" ]] && exit 0
    handle_choice "$choice"
}

main "$@"
