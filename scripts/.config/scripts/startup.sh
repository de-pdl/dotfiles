#!/bin/bash

# Variables (No spaces around =)
username="ayush"
script_dir="/home/$username/.config/scripts"

export POLY_FONT_SIZE=12
export POLY_OFFSET=0

# Clean Slate
APPS="picom dunst redshift polybar feh"
# killall -q $APPS
killall -9 $APPS 2>/dev/null

while pgrep -u $UID -x "$(echo $APPS | tr ' ' '|')" >/dev/null; do 
    sleep 0.1
done

# Monitor layout (Wait for this to finish)
$script_dir/sc_layout.sh

# Notification agent (Run in background with &)
dunst &

# Compositor (Run in background)
picom &

# free gpu
sleep 0.1

# Screen color
redshift &

# Background loader (Now it will finally reach this line!) + colors
$script_dir/bg_load.sh &

# Status bar (Run in background)
$script_dir/bar_launch.sh

$script_dir/tray_launch.sh &



### Refresh App Configs (maybe move this to another bash later)

# vim
for server in /run/user/$(id -u)/nvim.*; do
    (nvim --server "$server" --remote-send "<Esc>:source \$MYVIMRC<CR>:colorscheme matugen<CR>" &)
done

disown
