#!/bin/bash

# --- Configuration ---
# Define a mapping of folder name to the actual package name 
declare -A pkg_map=(
    ["nvim"]="neovim"
    ["alacritty"]="alacritty"
    ["i3"]="i3-wm"
    ["polybar"]="polybar"
    ["picom"]="picom"
    ["matugen"]="matugen"
)

# Navigate to the dotfiles directory
cd "$(dirname "$0")" || exit 1

# List of folders to stow
apps=(
    "scripts"
    "nvim"
    "alacritty"
    "i3"
    "polybar"
    "picom"
    "matugen"
)

# --- Functions ---
install_pkg() {
    local app=$1
    local package=${pkg_map[$app]:-$app} # Use map, fallback to app name

    if ! command -v "$app" &> /dev/null; then
        echo "📦 $app not found. Installing $package..."
        # Note: Change 'apt' to 'pacman', 'dnf', or 'brew' depending on your OS
        sudo apt update && sudo apt install -y "$package"
    else
        echo "✅ $app is already installed."
    fi
}

# --- Prerequisite Check ---
echo "Checking prerequisites..."
if ! command -v stow &> /dev/null; then
    echo "📦 stow not found. Installing stow..."
    sudo apt update && sudo apt install -y stow
else
    echo "✅ stow is already installed."
fi

# --- Execution ---
echo "Checking dependencies and mapping dotfiles..."

for app in "${apps[@]}"; do
    # Skip installation check for 'scripts' or non-binary folders
    if [[ "$app" != "scripts" ]]; then
        install_pkg "$app"
    fi
    
    # Run stow
    stow "$app"
done

echo "Done! Restart your shell to see changes."
