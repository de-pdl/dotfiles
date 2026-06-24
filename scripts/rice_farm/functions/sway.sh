#!/bin/bash
# Sway management functions

reload_sway() {
    log "Reloading Sway configuration..."
    swaymsg reload || error_exit "Failed to reload Sway"
    sleep 1
    export MATUGEN_PREFER="darkness"
    
    # Reapply monitor layout
    if [[ -f "$SCRIPTS_DIR/reload_monitors.sh" ]]; then
        bash "$SCRIPTS_DIR/reload_monitors.sh"
    else
        log "⚠️ reload_monitors.sh not found"
    fi
    
    sleep 1
    restart_waybar
    log "✅ Sway configuration reloaded"
}
