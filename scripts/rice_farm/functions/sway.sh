#!/bin/bash
# Sway management functions

reload_sway() {
    log "Reloading Sway configuration..."
    swaymsg reload || error_exit "Failed to reload Sway"
    sleep 1
    
    export MATUGEN_PREFER="darkness"
    validate_script "$SCRIPTS_DIR/bg_load.sh"
    "$SCRIPTS_DIR/bg_load.sh" &
    
    restart_waybar
    
    [[ -f "$HOME/.config/scripts/setup.sh" ]] && "$HOME/.config/scripts/setup.sh" &
    
    log "✅ Sway configuration reloaded"
    notify_success "Sway Config Reloaded"
}
