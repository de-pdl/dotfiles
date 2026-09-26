#!/bin/bash
# Menu display and choice handling

# The rofi script-mode control center owns page navigation and actions
# (ROFI_RETV/ROFI_INFO callbacks inside control_center.sh). show_menu runs
# the launch/handoff loop around it:
#
#   1. CC rofi: script-mode backend, list layout (cc_theme.rasi).
#   2. Gallery handshake file present after the CC rofi exits (Wallgallery
#      page was requested; the backend writes
#      ${XDG_CACHE_HOME:-$HOME/.cache}/rice_farm/open_gallery — the SAME
#      literal as GALLERY_HANDSHAKE below and in control_center.sh, kept
#      duplicated on purpose): rm -f the file and launch the gallery as its
#      OWN rofi process, fed the wp: rows by the backend in GALLERY_LIST
#      mode (RICE_CC_GALLERY=1) and themed with cc_gallery.rasi at window
#      creation (a script-mode \0theme snippet cannot re-layout geometry).
#      The first rofi has fully exited before the gallery starts, so two
#      rofi windows never stack (Ayush directive: no rofi inside rofi).
#      (An earlier port signaled the handoff with the backend's "exit 7":
#      rofi's own exit code never carried it — always 0 on the live boxes —
#      so the menu just closed. Verified live 2026-09-26.)
#   3. Escape/no pick in the gallery loops back to step 1 (the CC menu); a
#      pick is applied through the backend's existing act=wp: handler and
#      the CC does NOT reopen (old gallery.rasi picker UX).
#
# Any CC exit WITHOUT the handshake file (Esc = 1, ...) ends the menu like
# before. The rm -f runs BEFORE the gallery rofi starts, so a stale file
# can never re-open the gallery on the next menu launch. The loop is
# capped at CC_LOOP_MAX iterations against pathological relaunch loops.
# Runs under main_rice.sh's set -euo pipefail, hence the || st=$? guards.
# SCRIPTS_DIR is set by main_rice.sh before this file is sourced.
CC_LOOP_MAX=10

# Gallery handoff state file — MUST match GALLERY_HANDSHAKE in
# control_center.sh (same literal on purpose: one string, no shared
# config file). Written by the backend's page_wallgallery, consumed in
# show_menu below.
GALLERY_HANDSHAKE="${XDG_CACHE_HOME:-$HOME/.cache}/rice_farm/open_gallery"

show_menu() {
    local i=0 st picked
    while (( i < CC_LOOP_MAX )); do
        i=$(( i + 1 ))

        st=0
        rofi -show-icons -modi "rc:$SCRIPTS_DIR/control_center.sh" -show rc \
            -theme "$SCRIPTS_DIR/cc_theme.rasi" || st=$?
        # Gallery handoff is a state file, NOT an exit status (rofi's own
        # exit code never carried the backend's). The check runs on every
        # rofi exit status — Escape exits 1 and the || st=$? guard keeps
        # set -e from killing the loop. rm -f BEFORE the gallery rofi
        # starts: a stale file must not re-open the gallery on the next
        # menu launch.
        if [[ ! -f "$GALLERY_HANDSHAKE" ]]; then
            return "$st"   # normal close: no gallery requested
        fi
        rm -f "$GALLERY_HANDSHAKE"

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
