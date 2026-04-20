#!/bin/bash
# =============================================================================
# scripts/layout_picker.sh
#
# Entry point for layout selection. Shows a rofi menu of available layouts,
# lets the user pick one (or open settings), then launches it.
#
# Can be invoked:
#   - Standalone:        ./layout_picker.sh
#   - With layout arg:   ./layout_picker.sh 01-monitor.sh   (skips menu)
#   - From main_rice:    sourced, then handle_choice "Launch Layout"
#
# Menu structure:
#   󰕮 Layout 1: Monitor Dashboard
#   󰕮 Layout 2: Coding
#   ...
#   󰒓 Settings
# =============================================================================

set -euo pipefail

# --- Paths ---
RICE_DIR="$HOME/.config/scripts/rice_farm"
LAYOUTS_DIR="$RICE_DIR/data/layouts"
FUNCTIONS_DIR="$RICE_DIR/functions"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"
mkdir -p "$(dirname "$LOG_FILE")"

# --- Load the layout engine ---
# shellcheck disable=SC1091
source "$FUNCTIONS_DIR/layouts.sh"

# --------------------------------------------------------------------------
# discover_layouts : echoes "filename|display_name" for each layout file.
# Sorted by filename, so naming them 01-, 02- controls order in the menu.
# --------------------------------------------------------------------------
discover_layouts() {
    local file name
    # Process each layout file in sorted order.
    while IFS= read -r -d '' file; do
        # Source in a subshell to read LAYOUT_NAME without polluting our env.
        name=$(
            # shellcheck disable=SC1090
            source "$file" 2>/dev/null
            echo "${LAYOUT_NAME:-$(basename "$file" .sh)}"
        )
        echo "$(basename "$file")|$name"
    done < <(find "$LAYOUTS_DIR" -maxdepth 1 -name '*.sh' -print0 | sort -z)
}

# --------------------------------------------------------------------------
# show_settings_menu : submenu for tweaking persistent config values.
# Uses a two-step rofi flow: pick field, then enter/pick new value.
# --------------------------------------------------------------------------
show_settings_menu() {
    load_layout_config

    local options
    options=$(printf '%s\n' \
        "󰾫 Workspace: $LAYOUT_WORKSPACE" \
        "󱞬 Gap (px): $LAYOUT_GAP_PX" \
        "󰛖 Font (pt): $LAYOUT_FONT_PT" \
        "󰆍 Terminal: $LAYOUT_TERMINAL" \
        "󰌍 Back")

    local choice
    choice=$(echo "$options" | rofi -dmenu -i -p "󰒓 Layout Settings:" \
        -theme-str 'window {width: 30%;}')

    [[ -z "$choice" ]] && return 0

    case "$choice" in
        *Workspace*)
            local new
            new=$(rofi -dmenu -p "Workspace number:" <<< "$LAYOUT_WORKSPACE")
            [[ -n "$new" ]] && save_layout_config LAYOUT_WORKSPACE "$new"
            ;;
        *Gap*)
            local new
            new=$(rofi -dmenu -p "Gap in pixels:" <<< "$LAYOUT_GAP_PX")
            [[ -n "$new" ]] && save_layout_config LAYOUT_GAP_PX "$new"
            ;;
        *Font*)
            local new
            new=$(rofi -dmenu -p "Font size (pt):" <<< "$LAYOUT_FONT_PT")
            [[ -n "$new" ]] && save_layout_config LAYOUT_FONT_PT "$new"
            ;;
        *Terminal*)
            local new
            new=$(rofi -dmenu -p "Terminal command:" <<< "$LAYOUT_TERMINAL")
            [[ -n "$new" ]] && save_layout_config LAYOUT_TERMINAL "$new"
            ;;
        *Back*) return 0 ;;
    esac
}

# --------------------------------------------------------------------------
# show_main_menu : the top-level rofi picker. Returns the user's choice
# as a raw string (layout filename OR "settings" OR empty on cancel).
# --------------------------------------------------------------------------
show_main_menu() {
    local entries=()
    local filename display

    # Build menu entries from discovered layouts
    while IFS='|' read -r filename display; do
        entries+=( "󰕮 ${display} [${filename}]" )
    done < <(discover_layouts)

    entries+=( "󰒓 Settings" )

    local choice
    choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i \
        -p "󰕮 Layout:" -theme-str 'window {width: 35%;}' \
        -select "0")   # preselect first entry (default 1)

    echo "$choice"
}

# --------------------------------------------------------------------------
# handle_choice <choice_string>
# Dispatches based on the user's selection from show_main_menu.
# --------------------------------------------------------------------------
handle_choice() {
    local choice="$1"
    case "$choice" in
        *Settings*)
            show_settings_menu
            # After settings, loop back to main menu so user can launch
            main
            ;;
        *\[*.sh\]*)
            # Extract filename from "...[01-monitor.sh]"
            local filename="${choice##*[}"
            filename="${filename%]*}"
            launch_layout "$LAYOUTS_DIR/$filename"
            ;;
        "")
            exit 0
            ;;
        *)
            log "unknown choice: $choice"
            ;;
    esac
}

# --------------------------------------------------------------------------
# main : entry point. Accepts an optional layout filename as $1 to skip
# the menu entirely (useful for sway keybinds: bind layout_picker.sh
# 01-monitor.sh to a shortcut).
# --------------------------------------------------------------------------
main() {
    if [[ $# -gt 0 && -n "$1" ]]; then
        # Direct mode: launch a specific layout
        local target="$LAYOUTS_DIR/$1"
        if [[ -f "$target" ]]; then
            launch_layout "$target"
        else
            log "layout not found: $1"
            exit 1
        fi
        return
    fi

    # Interactive mode
    local choice
    choice=$(show_main_menu)
    handle_choice "$choice"
}

main "$@"
