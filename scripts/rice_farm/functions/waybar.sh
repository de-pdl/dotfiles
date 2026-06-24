#!/bin/bash
# Waybar management functions

restart_waybar() {
    log "Restarting Waybar..."
    pkill -f waybar || true
    sleep 0.3
    PATH="$HOME/.local/bin:$PATH" waybar > /dev/null 2>&1 &
}

change_waybar() {
    log "Opening waybar picker..."
    validate_script "$SCRIPTS_DIR/waybar_picker.sh"
    "$SCRIPTS_DIR/waybar_picker.sh"
}

refresh_waybar() {
    log "Refreshing Waybar..."
    restart_waybar
    log "✅ Waybar refreshed"
    notify_success "Waybar Refreshed"
}
