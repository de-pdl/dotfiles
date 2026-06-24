#!/usr/bin/env bash
# =============================================================================
# sway-workspace10-layout.sh
#
# Recreates a specific multi-window layout on Sway workspace 10.
# Resolution-independent: detects the usable area of the target workspace
# (excluding waybar / other reserved panels) and positions windows inside it.
#
# ---------------------------------------------------------------------------
# LAYOUT (percentages of usable workspace area):
#
#     X:     0%───40%─────────80%──100%
#     Y:
#      0%  ┌──────┬────────────┬────┐
#          │      │            │clk │    clock    (x 80-100, y 0-18)
#          │      ├────────────┴────┤
#     18%  │      │                 │
#          │ btop │      shell      │
#     60%  ├──────┤                 │
#          │ fast │                 │
#     80%  │fetch ├─────────────────┤
#          │      │      cava       │
#    100%  └──────┴─────────────────┘
#
# Cells (non-overlapping, verified):
#   btop       : x[ 0, 40]  y[ 0, 60]
#   fastfetch  : x[ 0, 40]  y[60,100]
#   clock      : x[80,100]  y[ 0, 18]
#   shell      : x[40,100]  y[18, 80]
#   cava       : x[40,100]  y[80,100]
#
# ---------------------------------------------------------------------------
# HOW IT WORKS:
#   1. Detects the focused output, switches to WS 10 on it.
#   2. Reads the workspace's usable rect from sway IPC (bar-aware — this is
#      the full output minus waybar and any other reserved space).
#   3. For each cell: launches alacritty, waits for its window to appear in
#      sway's tree, then positions that SPECIFIC window by its con_id.
#
# Sequential spawning + con_id targeting avoids the race conditions of
# for_window rules, which would otherwise match windows in arbitrary order.
#
# ---------------------------------------------------------------------------
# TO MODIFY THE LAYOUT:
#   - Edit the spawn_cell calls at the bottom. Args are:
#       spawn_cell <app_id> <x1%> <y1%> <x2%> <y2%> <alacritty args...>
#   - Coordinates are percentages of the usable workspace area.
#   - Keep cells non-overlapping (use the ASCII diagram above as reference).
#   - To change apps: modify the alacritty args after the coordinates.
#
# TO CHANGE FONT SIZE:
#   - Edit FONT_PT below. Lower = more content fits, harder to read.
#
# TO CHANGE WORKSPACE:
#   - Edit WS below.
#
# ---------------------------------------------------------------------------
# DEPENDENCIES:
#   sway, jq, alacritty, btop, fastfetch, fish, cava, tty-clock
# =============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# CONFIG
# ----------------------------------------------------------------------------
WS=10          # target workspace number
GAP_PX=8       # pixel gap between windows (prevents them from touching)
FONT_PT=8      # alacritty font size — small enough to fit btop's 80-col
               # minimum in a 40%-width cell on 1080p and up

# ----------------------------------------------------------------------------
# PRE-FLIGHT: make sure every binary we need is on PATH
# ----------------------------------------------------------------------------
for cmd in swaymsg jq alacritty btop fastfetch cava tty-clock; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing required command: $cmd" >&2
        exit 1
    }
done

# ----------------------------------------------------------------------------
# STEP 1: Find which output we're on and switch to workspace $WS there.
# We switch FIRST because get_workspaces' rect for WS only reflects the
# correct output after the workspace exists on that output.
# ----------------------------------------------------------------------------
focused_output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name')
if [ -z "$focused_output" ]; then
    echo "Could not detect focused output." >&2
    exit 1
fi

# Kill any leftover ws10-* windows from previous runs before switching,
# so we start with a clean workspace. The grep guard avoids a "no matching
# node" error when there's nothing to kill.
if swaymsg -t get_tree | grep -q '"app_id": "ws10-'; then
    swaymsg '[app_id="^ws10-.*"] kill' >/dev/null
    sleep 0.4   # give sway time to process the kills
fi

swaymsg "workspace number $WS" >/dev/null
sleep 0.1

# ----------------------------------------------------------------------------
# STEP 2: Read the USABLE rect for workspace $WS.
#
# This rect is the output size MINUS any space reserved by bars (waybar etc).
# That's the key fix for "bottom windows bleed under the bar": using the
# output's full rect would include waybar's strip, making our 100% taller
# than the actual usable area.
#
# .rect.x / .rect.y are global sway coordinates (accounting for multi-monitor
# offsets), so windows positioned inside this rect will land correctly
# regardless of which monitor we're on.
# ----------------------------------------------------------------------------
ws_rect=$(swaymsg -t get_workspaces | jq --arg ws "$WS" '.[] | select(.num == ($ws|tonumber)) | .rect')
if [ -z "$ws_rect" ] || [ "$ws_rect" = "null" ]; then
    echo "Could not read rect for workspace $WS." >&2
    exit 1
fi

WS_X=$(echo "$ws_rect" | jq -r '.x')
WS_Y=$(echo "$ws_rect" | jq -r '.y')
WS_W=$(echo "$ws_rect" | jq -r '.width')
WS_H=$(echo "$ws_rect" | jq -r '.height')

echo "Output: $focused_output"
echo "Usable workspace $WS area: ${WS_W}x${WS_H} at global (${WS_X},${WS_Y})"

# ----------------------------------------------------------------------------
# HELPERS: convert percent to pixels within the usable workspace rect
# ----------------------------------------------------------------------------
pct_w() { echo $(( $1 * WS_W / 100 )); }   # percent of usable width -> px
pct_h() { echo $(( $1 * WS_H / 100 )); }   # percent of usable height -> px

# ----------------------------------------------------------------------------
# spawn_cell: launch an alacritty instance in a specific grid cell.
#
# Usage: spawn_cell <app_id> <x1%> <y1%> <x2%> <y2%> <alacritty args...>
#
# Flow:
#   1. Snapshot existing con_ids for this app_id (should be 0 normally)
#   2. Launch alacritty with --class=<app_id>
#   3. Poll sway's tree until a NEW con_id with this app_id appears
#   4. Apply geometry to that specific con_id
#
# This is more reliable than for_window rules because we target by the
# unique con_id of the exact window we just spawned — no possibility of
# a rule matching the wrong window.
# ----------------------------------------------------------------------------
spawn_cell() {
    local id="$1" x1="$2" y1="$3" x2="$4" y2="$5"
    shift 5   # remaining args go to alacritty

    # Convert grid cell (percent) to pixel geometry, applying the gap so
    # adjacent windows don't visually touch.
    local px=$(( WS_X + $(pct_w "$x1") + GAP_PX ))
    local py=$(( WS_Y + $(pct_h "$y1") + GAP_PX ))
    local pw=$(( $(pct_w "$x2") - $(pct_w "$x1") - GAP_PX * 2 ))
    local ph=$(( $(pct_h "$y2") - $(pct_h "$y1") - GAP_PX * 2 ))

    printf "  %-16s %4dx%-4d  at  %4d,%-4d\n" "$id" "$pw" "$ph" "$px" "$py"

    # Get the set of con_ids that already exist for this app_id (usually
    # empty). We'll diff against this to find the new window.
    local before
    before=$(swaymsg -t get_tree | \
        jq --arg id "$id" '[.. | objects | select(.app_id? == $id) | .id]')

    # Launch alacritty. --class sets the app_id; -o overrides font size.
    alacritty --class "$id" -o "font.size=$FONT_PT" "$@" >/dev/null 2>&1 &
    disown

    # Poll up to ~5s for the new window to appear. We diff current con_ids
    # against the "before" snapshot to isolate the new one.
    local new_id=""
    for _ in {1..50}; do
        sleep 0.1
        new_id=$(swaymsg -t get_tree | jq --arg id "$id" --argjson before "$before" -r '
            [.. | objects | select(.app_id? == $id) | .id] as $now
            | ($now - $before)[0] // empty
        ')
        [ -n "$new_id" ] && break
    done

    if [ -z "$new_id" ]; then
        echo "  ! $id did not appear in time" >&2
        return 1
    fi

    # Apply geometry to this exact window. Order matters:
    #   1. Move to target workspace (in case it spawned elsewhere)
    #   2. Enable floating (required before resize/move position work)
    #   3. Disable border (borders add pixels and break our cell math)
    #   4. Resize to cell dimensions
    #   5. Move to cell origin
    swaymsg "[con_id=$new_id] move container to workspace number $WS" >/dev/null
    swaymsg "[con_id=$new_id] floating enable"                        >/dev/null
    swaymsg "[con_id=$new_id] border none"                            >/dev/null
    swaymsg "[con_id=$new_id] resize set width ${pw} px height ${ph} px" >/dev/null
    swaymsg "[con_id=$new_id] move position ${px} px ${py} px"        >/dev/null
}

# ----------------------------------------------------------------------------
# STEP 3: Spawn each window in its cell. Order is arbitrary because each
# call is self-contained and waits for its own window.
#
# Cell layout reference (see diagram at top):
#     id           x1  y1  x2  y2    content
#   ------------   --  --  --  ---   ---------------------------------------
# ----------------------------------------------------------------------------

# btop (system monitor) — top-left large block
spawn_cell "ws10-btop"       0   0  40  60 \
    -e btop

# fastfetch (system info) — bottom-left
# We wrap with `sh -c "...; exec sleep infinity"` so the terminal stays open
# after fastfetch prints and exits, and doesn't get closed by stray keys.
spawn_cell "ws10-fastfetch"  0  60  40 100 \
    -e sh -c "fastfetch; exec sleep infinity"

# tty-clock — small top-right corner
# -c centers; -C 4 sets the color (4 = blue-ish, adjust to taste)
spawn_cell "ws10-clock"     80   0 100  18 \
    -e tty-clock -c -C 4

# Interactive shell — right-middle band, opens in ~/dotfiles
spawn_cell "ws10-shell"     40  18 100  80 \
    --working-directory "$HOME/dotfiles" -e fish

# cava (audio visualizer) — bottom-right
spawn_cell "ws10-cava"      40  80 100 100 \
    -e cava

echo "Layout loaded on workspace $WS."
