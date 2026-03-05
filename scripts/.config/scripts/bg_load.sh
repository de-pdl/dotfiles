#!/bin/bash

#THEME=("abstract" "calm" "geometry" "minimal" "poly" "basalt")
#THEME=("apocalypse" "decay" "industrial" "monochrome" "fogsmoke" "cold")
#THEME=("aerial" "fauna" "flowers" "mountain" "nature" "wave")
#THEME=("anime" "evangelion" "manga")
#THEME=("gruvbox" "nord" "solarized" "radium")

#SELECTED_FOLDER=${THEME[$RANDOM % ${#THEME[@]}]}

#WALLPAPER=$(find "$HOME/Pictures/walls_filtered/$SELECTED_FOLDER" -type f | shuf -n 1)

WALLPAPER=$(find "$HOME/Pictures/walls_filtered" -type f -print0 | shuf -z -n 1)

matugen image "$WALLPAPER"

killall feh
feh --bg-max "$WALLPAPER"

