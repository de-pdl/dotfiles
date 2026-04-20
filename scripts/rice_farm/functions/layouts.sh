#!/bin/bash
# =============================================================================
# functions/layouts.sh
#
# Core logic for the layout system. Provides:
#   - read_workspace_rect : gets bar-aware usable area of a workspace
#   - place_app           : launches one app into a grid cell on a workspace
#   - launch_layout       : reads a datablock, loops place_app for each row
#   - load_layout_config  : reads persisted settings (workspace, gap, font)
#
# Datablock row format (pipe-delimited, spaces around | are trimmed):
#   type | command | x1 y1 x2 y2 [ | key=value ... ]
#
# Where:
#   type     : "term" (wrap command in alacritty) or "app" (launch directly)
#   command  : the program + args to run
#   x1..y2   : grid cell as percentages of the usable workspace (0-100)
#   extras   : optional kv pairs, currently supported:
#                cwd=<path>   working directory for the process
#
# Example rows:
#   term | btop                                  |  0  0 40 60
#   term | fish                                  | 40 18 100 80 | cwd=~/dotfiles
#   app  | firefox                               |  0  0 100 100
# =============================================================================

# --------------------------------------------------------------------------
# log : append a timestamped message to $LOG_FILE (set by main_rice.sh).
# Safe no-op if LOG_FILE unset.
# --------------------------------------------------------------------------
log() {
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [layouts] $*" | tee -a "$LOG_FILE" >&2
    else
        echo "[layouts] $*" >&2
    fi
}

# --------------------------------------------------------------------------
# load_layout_config : source ~/.config/scripts/rice_farm/layout.conf if it
# exists, then apply defaults for anything not set. All settings are simple
# shell variable assignments in the conf file.
#
# Exports:
#   LAYOUT_WORKSPACE  (default 10)
#   LAYOUT_GAP_PX     (default 8)
#   LAYOUT_FONT_PT    (default 8)
#   LAYOUT_TERMINAL   (default alacritty)
# --------------------------------------------------------------------------
load_layout_config() {
    local conf="$HOME/.config/scripts/rice_farm/layout.conf"
    if [[ -f "$conf" ]]; then
        # shellcheck disable=SC1090
        source "$conf"
    fi
    : "${LAYOUT_WORKSPACE:=10}"
    : "${LAYOUT_GAP_PX:=8}"
    : "${LAYOUT_FONT_PT:=8}"
    : "${LAYOUT_TERMINAL:=alacritty}"
    export LAYOUT_WORKSPACE LAYOUT_GAP_PX LAYOUT_FONT_PT LAYOUT_TERMINAL
}

# --------------------------------------------------------------------------
# save_layout_config <key> <value>
# Updates a single setting in layout.conf, creating the file if needed.
# --------------------------------------------------------------------------
save_layout_config() {
    local key="$1" value="$2"
    local conf="$HOME/.config/scripts/rice_farm/layout.conf"
    mkdir -p "$(dirname "$conf")"
    touch "$conf"
    # Remove any existing line for this key, then append the new one.
    # Using a temp file because sed -i behavior varies across systems.
    grep -v "^${key}=" "$conf" > "${conf}.tmp" || true
    echo "${key}=\"${value}\"" >> "${conf}.tmp"
    mv "${conf}.tmp" "$conf"
    log "set $key=$value"
}

# --------------------------------------------------------------------------
# read_workspace_rect <ws_num>
# Echoes "x y width height" for the USABLE area of the given workspace
# (i.e. minus waybar / other exclusive zones).
#
# Includes a small retry loop because on the very first switch to a
# workspace, sway sometimes reports the rect before waybar has registered
# its exclusive zone — causing windows to bleed under the bar.
# --------------------------------------------------------------------------
read_workspace_rect() {
    local ws="$1"
    local rect x y w h
    for _ in {1..10}; do
        rect=$(swaymsg -t get_workspaces | \
            jq --arg ws "$ws" '.[] | select(.num == ($ws|tonumber)) | .rect')
        if [[ -n "$rect" && "$rect" != "null" ]]; then
            x=$(echo "$rect" | jq -r '.x')
            y=$(echo "$rect" | jq -r '.y')
            w=$(echo "$rect" | jq -r '.width')
            h=$(echo "$rect" | jq -r '.height')
            # Sanity: width/height must be positive and non-zero
            if [[ "$w" -gt 0 && "$h" -gt 0 ]]; then
                echo "$x $y $w $h"
                return 0
            fi
        fi
        sleep 0.1
    done
    return 1
}

# --------------------------------------------------------------------------
# place_app : launch ONE app into a specific grid cell on the current ws.
#
# Args:
#   $1  type    : "term" or "app"
#   $2  cmd     : the command string (will be eval'd for shell expansion)
#   $3  x1      : left edge, percent of workspace width
#   $4  y1      : top edge, percent of workspace height
#   $5  x2      : right edge, percent
#   $6  y2      : bottom edge, percent
#   $7  cwd     : working directory (optional, empty string if none)
#
# Requires these globals to be set by the caller:
#   WS_X, WS_Y, WS_W, WS_H  (from read_workspace_rect)
#   LAYOUT_WORKSPACE, LAYOUT_GAP_PX, LAYOUT_FONT_PT, LAYOUT_TERMINAL
#
# How it works:
#   1. Computes pixel geometry from the percent cell
#   2. Generates a unique app_id (ws{N}-slot-{UUID})
#   3. Snapshots con_ids that match that app_id (should be 0)
#   4. Launches the app with that app_id
#   5. Polls sway's tree until a new con_id with that app_id appears
#   6. Applies floating+resize+move to the NEW con_id specifically
#
# Targeting by con_id (not app_id) prevents race conditions when launching
# multiple apps in parallel — each place_app call only touches the one
# window it just spawned.
# --------------------------------------------------------------------------
place_app() {
    local type="$1" cmd="$2"
    local x1="$3" y1="$4" x2="$5" y2="$6"
    local cwd="${7:-}"

    # --- Pixel geometry ---
    #
    # Gap handling: only apply GAP_PX on edges that touch ANOTHER window,
    # not on edges that touch the workspace boundary. Sway's own `gaps`
    # setting (and the bar-aware usable rect) already handles spacing at
    # workspace edges — adding GAP_PX there creates a visible double-gap.
    #
    # half_gap on each inner edge gives a full GAP_PX between neighbors.
    local half_gap=$(( LAYOUT_GAP_PX / 2 ))
    local gap_left=$half_gap gap_top=$half_gap gap_right=$half_gap gap_bottom=$half_gap
    [[ "$x1" -eq 0   ]] && gap_left=0
    [[ "$y1" -eq 0   ]] && gap_top=0
    [[ "$x2" -eq 100 ]] && gap_right=0
    [[ "$y2" -eq 100 ]] && gap_bottom=0

    # Coordinate frame note:
    #   Sway's `move position X px Y px` for floating windows applies the
    #   WORKSPACE origin automatically. We send workspace-relative coords
    #   (0,0 = top-left of usable area, already below waybar) and sway
    #   adds WS_X/WS_Y internally. Adding WS_X/WS_Y ourselves would
    #   double-offset — symptom: windows appear 45px below waybar instead
    #   of flush with it.
    local px py pw ph
    px=$(( (x1 * WS_W / 100) + gap_left ))
    py=$(( (y1 * WS_H / 100) + gap_top ))
    pw=$(( (x2 * WS_W / 100) - (x1 * WS_W / 100) - gap_left - gap_right ))
    ph=$(( (y2 * WS_H / 100) - (y1 * WS_H / 100) - gap_top - gap_bottom ))

    # --- Unique app_id for this slot (so we can find THIS window later) ---
    # Using timestamp+random for uniqueness. Format: ws10-slot-<ts><rand>
    local slot_id
    slot_id="ws${LAYOUT_WORKSPACE}-slot-$(date +%s%N)-$RANDOM"

    log "place $type '$cmd' -> ${pw}x${ph} @ ${px},${py}  (id=$slot_id)"

    # --- Build the launch command ---
    # For terminal apps: wrap in alacritty with the slot_id as --class,
    # override font size, set working dir if provided.
    # For GUI apps: launch directly. We use --class where possible but most
    # GUI apps ignore it; we'll fall back to matching by pid if needed.
    local before
    before=$(swaymsg -t get_tree | jq --arg id "$slot_id" \
        '[.. | objects | select(.app_id? == $id) | .id]')

    case "$type" in
        term)
            local -a alargs=( --class "$slot_id" -o "font.size=$LAYOUT_FONT_PT" )
            [[ -n "$cwd" ]] && alargs+=( --working-directory "$(eval echo "$cwd")" )
            # -e takes the command as separate args, so we use `sh -c` to
            # preserve the user's raw command string with its quoting.
            "$LAYOUT_TERMINAL" "${alargs[@]}" -e sh -c "$cmd" &
            disown
            ;;
        app)
            # Launch GUI app directly. eval lets the datablock use expansions
            # like $HOME, but means the datablock must be trusted input.
            eval "$cmd" &
            disown
            ;;
        *)
            log "unknown type: $type"
            return 1
            ;;
    esac

    # --- Wait for the new window to appear ---
    # For "term" we can match by our custom app_id.
    # For "app" the real app_id is whatever the GUI app sets, so we instead
    # find any NEW window that appeared since we launched — tracked by diffing
    # ALL con_ids (not just those matching slot_id).
    local new_id=""
    if [[ "$type" == "term" ]]; then
        for _ in {1..50}; do
            sleep 0.1
            new_id=$(swaymsg -t get_tree | jq --arg id "$slot_id" --argjson before "$before" -r '
                [.. | objects | select(.app_id? == $id) | .id] as $now
                | ($now - $before)[0] // empty
            ')
            [[ -n "$new_id" ]] && break
        done
    else
        # "app" mode: snapshot ALL windows on any workspace, then find a new one
        local all_before
        all_before=$(swaymsg -t get_tree | \
            jq '[.. | objects | select(.app_id? != null or .window_properties? != null) | .id]')
        for _ in {1..80}; do  # GUI apps can take longer to appear
            sleep 0.15
            new_id=$(swaymsg -t get_tree | jq --argjson before "$all_before" -r '
                [.. | objects | select(.app_id? != null or .window_properties? != null) | .id] as $now
                | ($now - $before)[0] // empty
            ')
            [[ -n "$new_id" ]] && break
        done
    fi

    if [[ -z "$new_id" ]]; then
        log "  ! window did not appear for: $cmd"
        return 1
    fi

    # --- Position the exact window we just spawned ---
    #
    # Order matters AND timing matters:
    #   1. Move to target workspace
    #   2. Set floating — sway needs a moment to commit this before resize works
    #   3. Small sleep (~80ms) — without this, `resize set` often gets clamped
    #      to workspace size because the layout pass hasn't committed floating
    #      state yet. Symptom: windows all end up workspace-sized.
    #   4. Disable border (must come before resize because border pixels affect
    #      the computed size)
    #   5. Resize + reposition together (sway processes chained commands
    #      in one transaction)
    swaymsg "[con_id=$new_id] move container to workspace number $LAYOUT_WORKSPACE" >/dev/null
    swaymsg "[con_id=$new_id] floating enable"                                      >/dev/null
    sleep 0.08
    swaymsg "[con_id=$new_id] border none"                                          >/dev/null
    swaymsg "[con_id=$new_id] resize set width ${pw} px height ${ph} px, move position ${px} px ${py} px" >/dev/null

    # --- Verify: log the ACTUAL size sway assigned ---
    # If this doesn't match (pw, ph), we know the resize still didn't stick.
    local actual
    actual=$(swaymsg -t get_tree | jq --argjson id "$new_id" -r '
        .. | objects | select(.id? == $id) | "\(.rect.width)x\(.rect.height) @ \(.rect.x),\(.rect.y)"
    ' 2>/dev/null | head -1)
    log "  actual: $actual (wanted ${pw}x${ph} @ ${px},${py})"
}

# --------------------------------------------------------------------------
# parse_datablock_row <row> -> sets globals: ROW_TYPE ROW_CMD ROW_X1..ROW_Y2 ROW_CWD
# Parses one pipe-delimited row with trimming of whitespace around fields.
# --------------------------------------------------------------------------
parse_datablock_row() {
    local row="$1"
    # Split on | into array. Scope IFS so it doesn't leak to the rest of
    # the function (otherwise the coord `read` below would split on |, not
    # whitespace, and all four coords would land in ROW_X1).
    local parts
    IFS='|' read -ra parts <<< "$row"

    # Trim whitespace from each part
    local i
    for i in "${!parts[@]}"; do
        parts[i]="$(echo "${parts[i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    done

    ROW_TYPE="${parts[0]:-}"
    ROW_CMD="${parts[1]:-}"
    # Coords: single field "x1 y1 x2 y2" split on whitespace (default IFS)
    read -r ROW_X1 ROW_Y1 ROW_X2 ROW_Y2 <<< "${parts[2]:-}"
    # Extras: everything after index 2, parsed for k=v pairs
    ROW_CWD=""
    local extra
    for extra in "${parts[@]:3}"; do
        case "$extra" in
            cwd=*) ROW_CWD="${extra#cwd=}" ;;
        esac
    done
}

# --------------------------------------------------------------------------
# launch_layout <layout_file>
# Main entry: sources a datablock file, then loops over LAYOUT_APPS
# calling place_app for each.
# --------------------------------------------------------------------------
launch_layout() {
    local layout_file="$1"
    if [[ ! -f "$layout_file" ]]; then
        log "layout file not found: $layout_file"
        return 1
    fi

    load_layout_config

    # --- Source the datablock to get LAYOUT_NAME + LAYOUT_APPS ---
    LAYOUT_NAME=""
    LAYOUT_APPS=()
    # shellcheck disable=SC1090
    source "$layout_file"

    if [[ ${#LAYOUT_APPS[@]} -eq 0 ]]; then
        log "layout has no apps: $layout_file"
        return 1
    fi

    log "launching layout '${LAYOUT_NAME:-unnamed}' (${#LAYOUT_APPS[@]} apps) on ws $LAYOUT_WORKSPACE"

    # --- Clean any slot windows from a previous run of this workspace ---
    if swaymsg -t get_tree | grep -q "\"app_id\": \"ws${LAYOUT_WORKSPACE}-slot-"; then
        swaymsg "[app_id=\"^ws${LAYOUT_WORKSPACE}-slot-.*\"] kill" >/dev/null
        sleep 0.4
    fi

    # --- Switch to target workspace and read its usable rect ---
    swaymsg "workspace number $LAYOUT_WORKSPACE" >/dev/null
    sleep 0.15

    local rect
    rect=$(read_workspace_rect "$LAYOUT_WORKSPACE") || {
        log "failed to read workspace rect"
        return 1
    }
    read -r WS_X WS_Y WS_W WS_H <<< "$rect"
    log "usable area: ${WS_W}x${WS_H} @ (${WS_X},${WS_Y})"

    # --- Loop: parse each row, call place_app ---
    local row
    for row in "${LAYOUT_APPS[@]}"; do
        # Skip empty lines and shell-style comments
        [[ -z "${row// }" ]] && continue
        [[ "${row#"${row%%[![:space:]]*}"}" == \#* ]] && continue

        parse_datablock_row "$row"
        place_app "$ROW_TYPE" "$ROW_CMD" "$ROW_X1" "$ROW_Y1" "$ROW_X2" "$ROW_Y2" "$ROW_CWD"
    done

    log "layout complete"
}
