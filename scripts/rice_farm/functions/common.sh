#!/bin/bash
# Utility and common functions

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ Error: $1"
    notify-send -u critical "Rice Farm" "$1" 2>/dev/null || true
    exit 1
}

validate_script() {
    [[ -f "$1" && -x "$1" ]] || error_exit "Script not found: $1"
}

notify_success() {
    notify-send "Rice Farm" "$1" -i view-refresh 2>/dev/null || true
}

check_dependencies() {
    local deps=("rofi" "notify-send" "swaymsg" "waybar")
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || error_exit "$dep not installed"
    done
}
