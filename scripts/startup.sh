#!/bin/bash

# Variables - Updated for flat structure
username="ayush"
# After running install.sh, scripts will be at ~/.config/scripts/
script_dir="/home/$username/.config/scripts"

# Clean Slate (Wayland tools only)
# We add kanshi here to ensure we don't have multiple listeners
APPS="dunst gammastep waybar swaybg kanshi"
killall -q $APPS 2>/dev/null

# Wait for apps to die
while pgrep -u $UID -x "$(echo $APPS | tr ' ' '|')" >/dev/null; do 
    sleep 0.1
done

# --- Core Services ---

# 1. Monitor Layout (Kanshi is the master now)
kanshi &

# 2. Notification agent
dunst &

# 3. Screen color temperature (Wayland native)
gammastep &

# 4. Background & Colors (Your updated bg_load.sh)
$script_dir/bg_load.sh &

waybar &

# --- App Syncing ---

# Refresh Neovim colors (Works perfectly via socket)
for server in /run/user/$(id -u)/nvim.*; do
    (nvim --server "$server" --remote-send "<Esc>:source \$MYVIMRC<CR>:colorscheme matugen<CR>" &)
done

disown
