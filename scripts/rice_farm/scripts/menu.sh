#!/bin/bash
# Menu display and choice handling

# The rofi script-mode control center owns page navigation and actions
# (ROFI_RETV/ROFI_INFO callbacks inside control_center.sh). show_menu runs
# the launch/handoff loop around it:
#
#   1. CC rofi: script-mode backend, list layout (cc_theme.rasi).
#   2. Backend exit status 7 (Wallgallery page requested, see
#      control_center.sh): the CC rofi has exited — launch the gallery as
#      its OWN rofi process, fed the wp: rows by the backend in GALLERY_LIST
#      mode (RICE_CC_GALLERY=1) and themed with cc_gallery.rasi at window
#      creation (a script-mode \0theme snippet cannot re-layout geometry).
#      The first rofi has fully exited before the gallery starts, so two
#      rofi windows never stack (Ayush directive: no rofi inside rofi).
#   3. Escape/no pick in the gallery loops back to step 1 (the CC menu); a
#      pick is applied through the backend's existing act=wp: handler and
#      the CC does NOT reopen (old gallery.rasi picker UX).
#
# Any other CC exit (Esc = 1, ...) ends the menu like before. The loop is
# capped at CC_LOOP_MAX iterations against pathological relaunch loops.
# Runs under main_rice.sh's set -euo pipefail, hence the || st=$? guards.
# SCRIPTS_DIR is set by main_rice.sh before this file is sourced.
CC_LOOP_MAX=10

show_menu() {
    local i=0 st picked
    while (( i < CC_LOOP_MAX )); do
        i=$(( i + 1 ))

        st=0
        rofi -show-icons -modi "rc:$SCRIPTS_DIR/control_center.sh" -show rc \
            -theme "$SCRIPTS_DIR/cc_theme.rasi" || st=$?
        if (( st != 7 )); then
            return "$st"
        fi

        picked=""
        st=0
        picked=$(RICE_CC_GALLERY=1 "$SCRIPTS_DIR/control_center.sh" \
            | rofi -show-icons -dmenu -theme "$SCRIPTS_DIR/cc_gallery.rasi" -i) || st=$?
        if (( st != 0 )) || [[ -z "$picked" ]]; then
            continue   # Escape / no pick: back to the CC menu
        fi

        # Apply the pick via the existing backend wp: action; the post-action
        # page re-render is discarded (no rofi is watching it).
        ROFI_RETV=1 ROFI_INFO="tab=Wallpaper;act=wp:$picked" \
            "$SCRIPTS_DIR/control_center.sh" >/dev/null
        return 0
    done
    return 0
}

handle_choice() { :; }
