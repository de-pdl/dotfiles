#!/bin/bash
# Sway management functions

reload_sway() {
    log "Reloading Sway configuration..."
    swaymsg reload || error_exit "Failed to reload Sway"
    # swaymsg reload re-runs sway/config's exec_always lines, which invoke
    # startup.sh — that already restarts kanshi/gammastep/waybar and
    # reloads the wallpaper. Doing it again here raced a second kanshi
    # restart against the first and corrupted the monitor output mid-modeset
    # (symptom: partial black screen after reload).
    log "✅ Sway configuration reloaded"
}
