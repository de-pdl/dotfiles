#!/bin/bash
# Menu display and choice handling

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
