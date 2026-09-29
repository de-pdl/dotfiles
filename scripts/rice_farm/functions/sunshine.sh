#!/bin/bash
# Sunshine (Moonlight stream host) toggle: flips the systemd USER units
# ON/OFF persistently, so the chosen state survives reboot.
#
#   ON  - systemctl --user enable --now sunshine.service
#         (enabling sunshine is enough for boot: on hosts where the unit
#         carries Requires=sway-sunshine.service, the dependency is pulled
#         in automatically)
#   OFF - systemctl --user disable --now for every managed unit, each
#         guarded individually (a missing unit must not fail the toggle)
#
# The unit set differs per host: some boxes also run
# sway-sunshine.service, others have it retired/disabled. Managed set is
# detected at call time: sunshine.service always, sway-sunshine.service
# only if its user unit file exists. The leftover xvfb-sunshine.service is
# deliberately NOT managed here.

_sunshine_units() {
    local units=(sunshine.service)
    if [[ -f "$HOME/.config/systemd/user/sway-sunshine.service" ]]; then
        units+=(sway-sunshine.service)
    fi
    printf '%s\n' "${units[@]}"
}

# Pure read for the control-center row label: never mutates state, must not
# fail when systemctl has no user session (prints OFF and returns 0).
status_sunshine() {
    local st
    st=$(systemctl --user is-enabled sunshine.service 2>/dev/null) || true
    [[ "$st" == "enabled" ]] && printf 'ON\n' || printf 'OFF\n'
    return 0
}

sunshine_toggle() {
    local u
    if [[ "$(status_sunshine)" == "ON" ]]; then
        # ---- OFF ----------------------------------------------------------
        while IFS= read -r u; do
            systemctl --user disable --now "$u" >/dev/null 2>&1 || true
        done < <(_sunshine_units)
        log "Sunshine: OFF (disabled, survives reboot)"
        notify-send "Rice Farm" "Sunshine: OFF" 2>/dev/null || true
    else
        # ---- ON -----------------------------------------------------------
        # sunshine.service only: on hosts pairing it with sway-sunshine the
        # Requires= dependency enables/pulls the dep; where sway-sunshine is
        # retired it stays untouched.
        systemctl --user enable --now sunshine.service >/dev/null 2>&1 || true
        log "Sunshine: ON (enabled, survives reboot)"
        notify-send "Rice Farm" "Sunshine: ON" 2>/dev/null || true
    fi
    return 0
}
