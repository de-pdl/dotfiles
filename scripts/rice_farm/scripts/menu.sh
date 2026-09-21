#!/bin/bash
# Menu display and choice handling

show_menu() {
    local gaming_status=""
    [[ -f "${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm_gaming" ]] && gaming_status=" [ON]"
    local options="󰸉 Change Wallpaper\n󱁻 Change Waybar\n Random Wallpaper\n󰃢 Refresh Waybar\n󰖺 Gaming Mode${gaming_status}\n󰐥 Reload Sway"
    echo -e "$options" | rofi -dmenu -i -p "󰄼 Rice Management:" -theme-str 'window {width: 30%;}'
}

handle_choice() {
    case "$1" in
        "󰸉 Change Wallpaper") change_wallpaper ;;
        "󱁻 Change Waybar") change_waybar ;;
        " Random Wallpaper") random_wallpaper ;;
        "󰃢 Refresh Waybar") refresh_waybar ;;
        *"Gaming Mode"*) gaming_mode_toggle ;;
        "󰐥 Reload Sway") reload_sway ;;
        *) log "Unknown choice: $1" ;;
    esac
}
