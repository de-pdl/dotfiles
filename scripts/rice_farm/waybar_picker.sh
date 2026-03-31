#!/bin/bash
# waybar_picker.sh
set -euo pipefail

WAYBAR_DIR="$HOME/.dotfiles/waybar"
THEMES_DIR="$WAYBAR_DIR/themes"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

[[ -d "$THEMES_DIR" ]] || { log "❌ Themes not found"; exit 1; }

readarray -t themes < <(ls -d "$THEMES_DIR"/*/ 2>/dev/null | xargs -I {} basename {} | sort)
[[ ${#themes[@]} -eq 0 ]] && { log "❌ No themes"; exit 1; }

selected=$(printf '%s\n' "${themes[@]}" | rofi -dmenu -p "󱁻 Waybar Theme:")
[[ -z "$selected" ]] && exit 0

THEME_PATH="$THEMES_DIR/$selected"

log "Switching to: $selected"

ln -sf "$THEME_PATH/config" "$WAYBAR_DIR/config"
ln -sf "$THEME_PATH/style.css" "$WAYBAR_DIR/style.css"

log "Restarting Waybar..."
pkill waybar 2>/dev/null || true
sleep 1

nohup waybar > /dev/null 2>&1 &

sleep 1
log "✅ Theme: $selected"
notify-send "Rice Farm" "Waybar theme: $selected"
