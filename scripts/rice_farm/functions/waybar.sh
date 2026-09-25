#!/bin/bash
# Waybar management functions

restart_waybar() {
    log "Restarting Waybar..."
    pkill -x waybar 2>/dev/null || true
    sleep 0.4
    # Launch as a child of the sway session (survives rofi exit), with
    # setsid as fallback when swaymsg is unavailable (SSH/headless).
    if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null; then
        swaymsg exec -- "PATH=\"$HOME/.local/bin:$PATH\" setsid waybar >/dev/null 2>&1"
    else
        PATH="$HOME/.local/bin:$PATH" setsid --fork waybar >/dev/null 2>&1
    fi
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
