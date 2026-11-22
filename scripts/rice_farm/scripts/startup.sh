#!/bin/bash
# Variables - Updated for flat structure
username="ayush"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean Slate (Wayland tools only)
APPS="gammastep waybar kanshi"
killall -q $APPS 2>/dev/null

# Wait for apps to die (BOUNDED: at session start the sway exec_always
# waybar line can spawn AFTER our killall; an unbounded wait then spins
# forever on the fresh waybar and kanshi/gammastep/bg_load never run).
for _w in $(seq 1 50); do
    pgrep -u "$UID" -x "$(echo $APPS | tr ' ' '|')" >/dev/null 2>&1 || break
    killall -q $APPS 2>/dev/null || true
    sleep 0.1
done


# --- Core Services ---
# 1. Monitor Layout (Kanshi is the master now)
# A kanshi death leaves a stale varlink socket that blocks every relaunch
# ("Failed to start Varlink listener") — clear it, retry, keep stderr logged.
_rt_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}"
rm -f "$_rt_dir"/fr.emersion.kanshi.* 2>/dev/null || true
for _try in 1 2 3; do
    kanshi > "$HOME/.local/state/kanshi.log" 2>&1 &
    sleep 2
    pgrep -x kanshi >/dev/null 2>&1 && break
    rm -f "$_rt_dir"/fr.emersion.kanshi.* 2>/dev/null || true
done
sleep 1  # Give kanshi time to start and read current state


# 2. Notification agent
# dunst & (in swayrc)

# 3. Screen color temperature (Wayland native)
gammastep &

# 4. Background & Colors
$script_dir/bg_load.sh &

waybar &

disown
