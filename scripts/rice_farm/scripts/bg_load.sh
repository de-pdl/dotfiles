#!/bin/bash
# ~/.config/scripts/rice_farm/bg_load.sh
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
MATUGEN_PREFER="${MATUGEN_PREFER:-darkness}"
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

select_wallpaper() {
    local wallpaper
    wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -print0 | \
        xargs -0 -I {} basename {} | \
        rofi -dmenu -i -p "󰸉 Select Wallpaper:" -theme-str 'window {width: 40%; height: 50%;}')
    
    [[ -z "$wallpaper" ]] && return 1
    
    local full_path
    full_path=$(find "$WALLPAPER_DIR" -type f -name "$wallpaper" | head -n1)
    [[ -z "$full_path" ]] && error_exit "Wallpaper not found: $wallpaper"
    echo "$full_path"
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
update_swaylock() {
    local wallpaper="$1"
    local swaylock_config="$HOME/.config/swaylock/config"
    if [[ ! -f "$swaylock_config" ]]; then
        log "⚠️  swaylock config not found, skipping"
        return 0
    fi
    # Update image path (handles spaces around =)
    if grep -q "^image" "$swaylock_config"; then
        sed -i "s|^image.*|image=$wallpaper|" "$swaylock_config"
    else
        echo "image=$wallpaper" >> "$swaylock_config"
    fi
    log "🔐 Swaylock updated with: $(basename "$wallpaper")"
}

trigger_config_reloads() {
    local wallpaper="$1"
    # Update swaylock
    update_swaylock "$wallpaper"
    # Trigger alacritty config reload
    if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then
        touch "$HOME/.config/alacritty/alacritty.toml"
    fi
    # Trigger neovim config reload
    if [[ -f "$HOME/.config/nvim/init.lua" ]]; then
        touch "$HOME/.config/nvim/init.lua"
    fi
    # Trigger waybar reload
    pkill -USR2 waybar 2>/dev/null || true
    # Trigger rofi reload
    pkill rofi 2>/dev/null || true
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    validate_wallpaper_dir
    
    local wallpaper
    
    # If arg provided, use it; otherwise random
    if [[ $# -gt 0 && -n "$1" ]]; then
        if [[ -f "$1" ]]; then
            wallpaper="$1"
            log "📸 Using provided wallpaper: $(basename "$wallpaper")"
        else
            error_exit "Provided wallpaper not found: $1"
        fi
    else
        wallpaper=$(find_random_wallpaper)
    fi
    
    set_wallpaper "$wallpaper"
    generate_colors "$wallpaper"
    trigger_config_reloads "$wallpaper"
    log "✅ Wallpaper and colors loaded successfully"
    notify-send "Rice Farm" "Wallpaper: $(basename "$wallpaper")" -i dialog-information
}

main "$@"
