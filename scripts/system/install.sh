#!/bin/bash

echo "🔗 Starting dotfile mapping..."
echo "⚠️  Ensure you have run ./scripts/system/install_dependencies.sh and ./scripts/system/setup.sh first!"
echo ""

# Navigate to the dotfiles directory safely
DOTFILES_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
CONFIG_DIR="$HOME/.config"

# Ensure ~/.config exists
mkdir -p "$CONFIG_DIR"

# --- Configuration ---
# Folders at dotfiles root to symlink into ~/.config/
config_folders=(

    # text editor, bash profile, terminal
    "nvim"
    "fish"
    "alacritty"

    # system sway and lock
    "sway"
    "swaylock"
    
    # bar, screen manager, color manager
    "waybar" 
    "kanshi"
    "matugen"

    # demenu
    "rofi"
)

# --- Helper function ---
link_config() {
    local source="$1"
    local target="$2"
    local name="$3"
    
    if [ ! -d "$source" ] && [ ! -f "$source" ]; then
        echo "⏭️  Skipping $name (Not found: $source)"
        return 0
    fi
    
    echo "🔗 Linking $name..."
    
    # Check if target exists (file or symlink)
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "   ⚠️  Found existing config, removing..."
        rm -rf "$target"
    fi
    
    # Create symlink
    if ln -s "$source" "$target"; then
        echo "   ✅ Linked: $target → $source"
    else
        echo "   ❌ Failed to link $name"
        return 1
    fi
}

# --- Execution ---
echo "📁 Linking config directories..."
for folder in "${config_folders[@]}"; do
    link_config "$DOTFILES_DIR/$folder" "$CONFIG_DIR/$folder" "$folder"
done

# --- Post-Install Hooks ---
echo ""
echo "🔄 Reloading Wayland environment..."

# 1. Reload Sway
if pgrep -x "sway" > /dev/null; then
    echo "   Reloading Sway..."
    swaymsg reload > /dev/null && echo "   ✅ Sway reloaded"
fi

# 2. Reload Waybar
if pgrep -x "waybar" > /dev/null; then
    echo "   Reloading Waybar..."
    killall -SIGUSR2 waybar && echo "   ✅ Waybar reloaded"
fi

# 3. Restart Kanshi
if pgrep -x "kanshi" > /dev/null; then
    echo "   Restarting Kanshi..."
    pkill kanshi
    sleep 0.5
    kanshi & disown
    echo "   ✅ Kanshi restarted"
fi

# 4. Restart dunst (notification daemon)
if pgrep -x "dunst" > /dev/null; then
    echo "   Restarting Dunst..."
    pkill dunst
    sleep 0.5
    dunst & disown
    echo "   ✅ Dunst restarted"
fi

echo ""
echo "🎉 All done! Your dotfiles are directly linked and active."
