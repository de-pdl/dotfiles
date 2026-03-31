#!/bin/bash
# ~/.config/scripts/rice_farm/bg_load.sh
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
MATUGEN_PREFER="${MATUGEN_PREFER:-darkness}"  # Default to darkness
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
    notify-send -u critical "Rice Farm" "$1"
    exit 1
}

# ============================================================================
# WALLPAPER FUNCTIONS
# ============================================================================

validate_wallpaper_dir() {
    [[ -d "$WALLPAPER_DIR" ]] || error_exit "Wallpaper directory not found: $WALLPAPER_DIR"
}

find_random_wallpaper() {
    local wallpaper
    wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -print0 | shuf -z -n 1 | tr -d '\0')
    [[ -z "$wallpaper" ]] && error_exit "No wallpaper found in $WALLPAPER_DIR"
    echo "$wallpaper"
}

set_wallpaper() {
    local wallpaper="$1"
    log "🎨 Loading wallpaper: $(basename "$wallpaper")"
    
    if ! swaymsg output "*" bg "$wallpaper" fill 2>/dev/null; then
        error_exit "Failed to set wallpaper with swaymsg"
    fi
}

# ============================================================================
# COLOR GENERATION FUNCTIONS
# ============================================================================

generate_colors() {
    local wallpaper="$1"
    
    if ! command -v matugen &> /dev/null; then
        log "⚠️  matugen not found, skipping color generation"
        return 0
    fi
    
    log "🎨 Generating colors with matugen (preference: $MATUGEN_PREFER)..."
    
    if matugen image "$wallpaper" -m dark --prefer="$MATUGEN_PREFER"; then
        log "✅ Colors generated"
    else
        log "⚠️  matugen failed (non-fatal)"
    fi
}

# ============================================================================
# CONFIG RELOAD FUNCTIONS
# ============================================================================

trigger_config_reloads() {
    # Trigger alacritty config reload
    if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then
        touch "$HOME/.config/alacritty/alacritty.toml"
    fi
    
    # Trigger waybar reload
    pkill -USR2 waybar 2>/dev/null || true
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    validate_wallpaper_dir
    
    local wallpaper
    wallpaper=$(find_random_wallpaper)
    
    set_wallpaper "$wallpaper"
    generate_colors "$wallpaper"
    trigger_config_reloads
    
    log "✅ Wallpaper and colors loaded successfully"
    notify-send "Rice Farm" "Wallpaper: $(basename "$wallpaper")" -i dialog-information
}

main "$@"
