#!/bin/bash
# Wallpaper management functions

choose_matugen_preference() {
    local options="darkness\nlightness\nsaturation\nless-saturation\nvalue\nclosest-to-fallback"
    echo -e "$options" | rofi -dmenu -i -p "󰨇 Color Preference:" -theme-str 'window {width: 20%;}'
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
