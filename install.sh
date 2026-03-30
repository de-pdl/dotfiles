#!/bin/bash

echo "🔗 Starting dotfile mapping..."
echo "⚠️  Ensure you have run ./install_dependencies.sh and ./setup.sh first!"
echo ""

# Navigate to the dotfiles directory safely
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

# Ensure ~/.config exists
mkdir -p "$CONFIG_DIR"

# --- Configuration ---
# Folders inside your flattened dotfiles repo to symlink
folders=(
    "scripts"
    "nvim"
    "alacritty"
    "sway"
    "waybar"
    "kanshi"
    "matugen"
    "rofi"
)

# --- Execution ---
for folder in "${folders[@]}"; do
    # Skip if the folder doesn't exist in the repo (just in case)
    if [ ! -d "$DOTFILES_DIR/$folder" ]; then
        echo "⏭️  Skipping $folder (Not found in dotfiles directory)"
        continue
    fi

    echo "🔗 Linking $folder..."
    
    # Check if a physical file/directory OR a symlink exists at the target and delete it
    if [ -e "$CONFIG_DIR/$folder" ] || [ -L "$CONFIG_DIR/$folder" ]; then
        echo "   ⚠️  Found existing config, removing..."
        rm -rf "$CONFIG_DIR/$folder"
    fi

    # Create the clean, direct symlink
    ln -s "$DOTFILES_DIR/$folder" "$CONFIG_DIR/$folder"
    echo "   ✅ Linked"
done

# --- Post-Install Hooks ---
echo ""
echo "🔄 Reloading Wayland environment..."

# 1. Reload Sway (Restarts in place without closing your apps)
if pgrep -x "sway" > /dev/null; then
    echo "Reloading Sway..."
    swaymsg reload > /dev/null
fi

# 2. Reload Waybar (Hot-reloads CSS/Config without killing the process)
if pgrep -x "waybar" > /dev/null; then
    echo "Reloading Waybar..."
    killall -SIGUSR2 waybar
fi

# 3. Restart Kanshi (Monitor manager)
if pgrep -x "kanshi" > /dev/null; then
    echo "Restarting Kanshi..."
    pkill kanshi
    kanshi & disown
fi

echo "🎉 All done! Your dotfiles are directly linked and active."
