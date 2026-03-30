#!/bin/bash

echo "🚀 Starting Sway/Wayland app installation and dotfile mapping..."

# Navigate to the dotfiles directory safely
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

# Ensure ~/.config exists
mkdir -p "$CONFIG_DIR"

# --- Configuration ---
# Map the dotfile folders to the actual Arch/AUR package names needed
declare -A pkg_map=(
    ["nvim"]="neovim"
    ["alacritty"]="alacritty"
    ["sway"]="sway swaybg swaylock swayidle"
    ["waybar"]="waybar"
    ["matugen"]="matugen"
    ["kanshi"]="kanshi"
    ["rofi"]="rofi-wayland"
    ["scripts"]="grim slurp wl-clipboard gammastep" # Extra tools needed by your scripts
)

# Folders inside your dotfiles repo to symlink
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

# --- Functions ---
install_pkg() {
    local folder=$1
    local packages=${pkg_map[$folder]:-$folder}

    echo "📦 Checking packages for $folder: $packages..."
    
    # Use yay without sudo. --needed prevents reinstalling.
    if ! yay -S --needed --noconfirm $packages; then
        echo "❌ Failed to install $packages. Please check your connection or the AUR."
    else
        echo "✅ $packages installed/ready."
    fi
}

# --- Execution ---
for folder in "${folders[@]}"; do
    # Install dependencies associated with this folder
    install_pkg "$folder"

    echo "🔗 Linking $folder..."
    
    # Check if a physical file/directory OR a symlink exists at the target and delete it
    if [ -e "$CONFIG_DIR/$folder" ] || [ -L "$CONFIG_DIR/$folder" ]; then
        echo "⚠️  Found existing config for $folder, removing..."
        rm -rf "$CONFIG_DIR/$folder"
    fi

    # Create the clean, direct symlink
    ln -s "$DOTFILES_DIR/$folder" "$CONFIG_DIR/$folder"
done

# --- Post-Install Hooks ---
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

echo "🎉 All done! Your new Wayland dotfiles are linked and active."
