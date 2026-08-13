#!/bin/bash
# Quick-access system settings: volume, brightness, night light.
#
# Each of these stays open after every action (nudge up/down, toggle,
# type an exact value) instead of exiting on the first Enter, so a
# misclick is just another keypress away from being fixed, not a full
# re-navigation back through the menu tree.

volume_settings() {
    while true; do
        local current muted mute_label options choice
        current=$(pamixer --get-volume 2>/dev/null || echo "?")
        muted=$(pamixer --get-mute 2>/dev/null)
        mute_label="Mute"
        [[ "$muted" == "true" ]] && mute_label="Unmute"

        options="󰝝 +5%\n󰝞 -5%\n ${mute_label}\n Set exact %\n󰌍 Back"
        choice=$(echo -e "$options" | rofi -dmenu -i -p "󰕾 Volume: ${current}%" -theme "$ROFI_MENU_THEME")

        case "$choice" in
            *+5%*)
                pamixer --unmute >/dev/null 2>&1
                pamixer -i 5
                ;;
            *-5%*)
                pamixer -d 5
                ;;
            *Mute*|*Unmute*)
                pamixer -t
                ;;
            *"Set exact"*)
                local val
                val=$(rofi -dmenu -p "Volume %:" -theme "$ROFI_MENU_THEME" <<< "$current")
                if [[ "$val" =~ ^[0-9]+$ ]]; then
                    pamixer --unmute >/dev/null 2>&1
                    pamixer --set-volume "$val"
                fi
                ;;
            "󰌍 Back"|"")
                return 0
                ;;
        esac
    done
}

brightness_settings() {
    while true; do
        local current options choice
        current=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')
        [[ -z "$current" ]] && current="?"

        options=" +5%\n -5%\n Set exact %\n󰌍 Back"
        choice=$(echo -e "$options" | rofi -dmenu -i -p "󰃟 Brightness: ${current}%" -theme "$ROFI_MENU_THEME")

        case "$choice" in
            *+5%*) brightnessctl set +5% >/dev/null ;;
            *-5%*) brightnessctl set 5%- >/dev/null ;;
            *"Set exact"*)
                local val
                val=$(rofi -dmenu -p "Brightness %:" -theme "$ROFI_MENU_THEME" <<< "$current")
                [[ "$val" =~ ^[0-9]+$ ]] && brightnessctl set "${val}%" >/dev/null
                ;;
            "󰌍 Back"|"")
                return 0
                ;;
        esac
    done
}

# --------------------------------------------------------------------------
# Night light: gammastep has no relative-adjust flag (only a one-shot
# absolute -O <temp>, or continuous auto mode with no arg), so the last
# manually-set temperature is tracked in a small state file to make
# +/- nudges possible.
# --------------------------------------------------------------------------
_night_light_state_file() {
    echo "${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm_night_temp"
}

_night_light_apply() {
    local temp="$1"
    pkill gammastep 2>/dev/null
    sleep 0.15
    gammastep -O "$temp" >/dev/null 2>&1 &
    disown
    echo "$temp" > "$(_night_light_state_file)"
}

night_light_settings() {
    local state_file
    state_file="$(_night_light_state_file)"
    mkdir -p "$(dirname "$state_file")"

    while true; do
        local status="Off" current_temp options choice
        pgrep -x gammastep >/dev/null && status="On"
        current_temp=$(cat "$state_file" 2>/dev/null || echo "auto")

        options="󰛨 Toggle (${status})\n Cooler (+250K)\n Warmer (-250K)\n Set exact K\n󰃟 Reset to Auto\n󰌍 Back"
        choice=$(echo -e "$options" | rofi -dmenu -i -p "󰌵 Night Light: ${current_temp}" -theme "$ROFI_MENU_THEME")

        case "$choice" in
            *Toggle*)
                if pgrep -x gammastep >/dev/null; then
                    pkill gammastep
                else
                    gammastep >/dev/null 2>&1 &
                    disown
                    rm -f "$state_file"
                fi
                ;;
            *Cooler*)
                local base=$(cat "$state_file" 2>/dev/null || echo 6500)
                _night_light_apply $(( base + 250 > 6500 ? 6500 : base + 250 ))
                ;;
            *Warmer*)
                local base=$(cat "$state_file" 2>/dev/null || echo 6500)
                _night_light_apply $(( base - 250 < 1000 ? 1000 : base - 250 ))
                ;;
            *"Set exact"*)
                local val
                val=$(rofi -dmenu -p "Temp (K):" -theme "$ROFI_MENU_THEME" <<< "$current_temp")
                [[ "$val" =~ ^[0-9]+$ ]] && _night_light_apply "$val"
                ;;
            *"Reset to Auto"*)
                pkill gammastep 2>/dev/null
                sleep 0.15
                gammastep >/dev/null 2>&1 &
                disown
                rm -f "$state_file"
                ;;
            "󰌍 Back"|"")
                return 0
                ;;
        esac
    done
}
