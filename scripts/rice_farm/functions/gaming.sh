#!/bin/bash
# Gaming Mode toggle: one press flips the machine between "gaming" and
# "desktop" states.
#
#   ON  - CPU governor -> performance
#       - llama-server stopped (frees VRAM + CPU cores)
#       - gammastep (night light) stopped, remembered for restore
#   OFF - CPU governor -> powersave (amd-pstate-epp offers only performance/powersave)
#       - gammastep restarted only if it was running before ON
#
# Governor changes need root; a sudoers rule allows them without a
# password. If sudo -n fails we notify and continue with the rest.

GAMING_STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm_gaming"

_gaming_set_governor() {
    local gov="$1"
    if sudo -n /usr/bin/cpupower frequency-set -g "$gov" >/dev/null 2>&1; then
        return 0
    fi
    notify-send -u critical "Rice Farm" \
        "Gaming Mode: governor switch to $gov failed" 2>/dev/null || true
    return 1
}

gaming_mode_toggle() {
    if [[ -f "$GAMING_STATE_FILE" ]]; then
        # ---- OFF ----------------------------------------------------------
        # gammastep restore flag lives in a sidecar so it survives the
        # state-file removal that marks the mode as off.
        if [[ -f "${GAMING_STATE_FILE}.gamma" ]]; then
            gammastep >/dev/null 2>&1 &
            disown
            rm -f "${GAMING_STATE_FILE}.gamma"
        fi
        rm -f "$GAMING_STATE_FILE"
        _gaming_set_governor powersave
        sudo -n systemctl stop gaming-net >/dev/null 2>&1 || true
        log "Gaming Mode: OFF (governor powersave)"
        notify-send "Rice Farm" "Gaming Mode: OFF" 2>/dev/null || true
    else
        # ---- ON -----------------------------------------------------------
        mkdir -p "$(dirname "$GAMING_STATE_FILE")"
        date -Is > "$GAMING_STATE_FILE"
        if pgrep -x gammastep >/dev/null 2>&1; then
            touch "${GAMING_STATE_FILE}.gamma"
            pkill gammastep 2>/dev/null || true
        else
            rm -f "${GAMING_STATE_FILE}.gamma"
        fi
        pkill -f llama-server 2>/dev/null || true
        _gaming_set_governor performance
        # DSCP-mark game traffic (WMM priority over the wifi hop); needs the
        # rice-gaming sudoers rule, degrades to a notification if absent.
        if ! sudo -n systemctl start gaming-net >/dev/null 2>&1; then
            notify-send -u critical "Rice Farm" \
                "Gaming Mode: network priority needs sudoers setup" 2>/dev/null || true
        fi
        log "Gaming Mode: ON (governor performance, llama-server stopped)"
        notify-send "Rice Farm" "Gaming Mode: ON" 2>/dev/null || true
    fi
    return 0
}
