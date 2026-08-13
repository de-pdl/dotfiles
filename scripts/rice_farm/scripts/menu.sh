#!/bin/bash
# Menu display and choice handling

ROFI_MENU_THEME="$HOME/.config/rofi/menu.rasi"

show_menu() {
    local options="󰸉 Wallpaper\n󱁻 Waybar\n󰒓 Settings\n󰐥 Power\n󰑐 Reload Sway"
    echo -e "$options" | rofi -dmenu -i -p "󰄼 Rice Management:" -theme "$ROFI_MENU_THEME"
}

handle_choice() {
    case "$1" in
        "󰸉 Wallpaper") handle_wallpaper_menu ;;
        "󱁻 Waybar") handle_waybar_menu ;;
        "󰒓 Settings") handle_settings_menu ;;
        "󰐥 Power") handle_power_menu ;;
        "󰑐 Reload Sway") reload_sway ;;
        "") exit 0 ;;
        *) log "Unknown choice: $1" ;;
    esac
}

# --------------------------------------------------------------------------
# Submenus. Each shows a list ending in "Back", which re-opens the
# top-level menu. Selecting a real entry performs the action and exits,
# matching the original one-shot-per-invocation behavior.
# --------------------------------------------------------------------------

handle_wallpaper_menu() {
    local choice
    choice=$(echo -e "󰸉 Change Wallpaper\n Random Wallpaper\n󰌍 Back" | \
        rofi -dmenu -i -p "󰸉 Wallpaper:" -theme "$ROFI_MENU_THEME")
    case "$choice" in
        "󰸉 Change Wallpaper") change_wallpaper ;;
        " Random Wallpaper") random_wallpaper ;;
        "󰌍 Back") main ;;
    esac
}

handle_waybar_menu() {
    local choice
    choice=$(echo -e "󱁻 Change Theme\n󰃢 Refresh\n󰌍 Back" | \
        rofi -dmenu -i -p "󱁻 Waybar:" -theme "$ROFI_MENU_THEME")
    case "$choice" in
        "󱁻 Change Theme") change_waybar ;;
        "󰃢 Refresh") refresh_waybar ;;
        "󰌍 Back") main ;;
    esac
}

handle_settings_menu() {
    # Loops: volume/brightness/night_light each run their own nudge-loop
    # and return here (not exit) on Back, landing on this list again.
    while true; do
        local choice
        choice=$(echo -e "󰕾 Volume\n󰃟 Brightness\n󰌵 Night Light\n󰌍 Back" | \
            rofi -dmenu -i -p "󰒓 Settings:" -theme "$ROFI_MENU_THEME")
        case "$choice" in
            "󰕾 Volume") volume_settings ;;
            "󰃟 Brightness") brightness_settings ;;
            "󰌵 Night Light") night_light_settings ;;
            "󰌍 Back"|"") main; return 0 ;;
        esac
    done
}

handle_power_menu() {
    local choice
    choice=$(echo -e " Lock\n󰍃 Logout\n󰜉 Reboot\n󰐥 Shutdown\n󰌍 Back" | \
        rofi -dmenu -i -p "󰐥 Power:" -theme "$ROFI_MENU_THEME")
    case "$choice" in
        " Lock") power_lock ;;
        "󰍃 Logout") power_logout ;;
        "󰜉 Reboot") power_reboot ;;
        "󰐥 Shutdown") power_shutdown ;;
        "󰌍 Back") main ;;
    esac
}
