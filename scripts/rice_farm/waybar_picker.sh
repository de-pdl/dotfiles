#!/bin/bash
set -euo pipefail

WAYBAR_DIR="$HOME/.dotfiles/waybar"
THEMES_DIR="$WAYBAR_DIR/themes"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

readarray -t themes < <(ls -d "$THEMES_DIR"/*/ 2>/dev/null | xargs -I {} basename {} | sort)

selected=$(printf '%s\n' "${themes[@]}" | rofi -dmenu -p "󱁻 Waybar Theme:")
[[ -z "$selected" ]] && exit 0

log "Switching to: $selected"
ln -sf "$THEMES_DIR/$selected/config" "$WAYBAR_DIR/config"
ln -sf "$THEMES_DIR/$selected/style.css" "$WAYBAR_DIR/style.css"

pkill -15 -f "waybar$"
sleep 1

# Launch with explicit PATH in environment
PATH="$HOME/.local/bin:$PATH" waybar &

log "✅ Theme: $selected"
notify-send "Rice Farm" "Waybar theme: $selected"
