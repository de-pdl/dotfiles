#!/bin/bash
# Menu display and choice handling

# The rofi script-mode control center owns the whole interaction loop
# (pages, actions, re-renders happen inside control_center.sh via
# ROFI_RETV/ROFI_INFO). show_menu LAUNCHES rofi with the backend as a
# script-mode modi; rofi then drives control_center.sh per interaction.
# SCRIPTS_DIR is set by main_rice.sh before this file is sourced.
show_menu() {
    exec rofi -show-icons -modi "rc:$SCRIPTS_DIR/control_center.sh" -show rc \
        -theme "$SCRIPTS_DIR/cc_theme.rasi"
}

handle_choice() { :; }
