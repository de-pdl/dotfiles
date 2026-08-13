#!/bin/bash
# Power/session actions: lock, logout, reboot, shutdown

confirm_action() {
    local prompt="$1"
    local choice
    choice=$(printf '%s\n' "No" "Yes" | rofi -dmenu -i -p "$prompt" -theme "$ROFI_MENU_THEME")
    [[ "$choice" == "Yes" ]]
}

power_lock() {
    swaylock -f -c 000000
}

power_logout() {
    confirm_action "󰍃 Log out?" && swaymsg exit
}

power_reboot() {
    confirm_action "󰜉 Reboot?" && systemctl reboot
}

power_shutdown() {
    confirm_action "󰐥 Shut down?" && systemctl poweroff
}
