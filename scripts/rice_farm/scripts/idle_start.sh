#!/bin/bash
# Restart swayidle cleanly; called by sway config exec_always on launch/reload.
# Kept as a script (not an inline sh -c) so the multi-command swayidle line
# avoids sway-config semicolon splitting and nested-quoting pitfalls.
pkill -x swayidle 2>/dev/null || true
exec swayidle -w \
    timeout 300 'swaylock -f -c 000000' \
    timeout 600 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' \
    before-sleep 'loginctl lock-session' \
    lock 'swaylock -f -c 000000' \
    unlock 'killall swaylock' \
    timeout 1500 '/usr/local/sbin/cronos-idle-suspend --swayidle'
