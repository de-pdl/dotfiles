#!/bin/bash

# Navigate to the dotfiles directory
cd "$(dirname "$0")"

# List of folders to stow
apps=(

		# base tools
    "scripts"
    "nvim"
		"alacritty"

		# gui
    "i3"
    "polybar"
		"picom"

		# extra tools
		"matugen"
)

echo "Mapping dotfiles..."
for app in "${apps[@]}"; do
    stow "$app"
done

echo "Done! Restart your shell to see changes."
