#!/bin/bash

echo "🚀 Starting app installation and dotfile mapping..."

# Navigate to the dotfiles directory safely
cd "$(dirname "$0")" || exit 1

# --- Configuration ---
declare -A pkg_map=(
    ["nvim"]="neovim"
    ["alacritty"]="alacritty"
    ["i3"]="i3-wm"
    ["polybar"]="polybar"
    ["picom"]="picom"
    ["matugen"]="matugen"
)

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
    local package=${pkg_map[$app]:-$app}

    if ! command -v "$app" &> /dev/null; then
        echo "📦 $app not found. Installing $package via yay..."
        
        # Use yay without sudo. --needed prevents reinstalling.
        if ! yay -S --needed --noconfirm "$package"; then
            echo "❌ Failed to install $package. Please check the package name or your connection."
        fi
    else
        echo "✅ $app is already installed."
    fi
}

# --- Execution ---
for app in "${apps[@]}"; do
    if [[ "$app" != "scripts" ]]; then
        install_pkg "$app"
    fi

    echo "🔗 Stowing $app..."
    
    # Check if a physical file/directory exists at the target and delete it
    # This assumes your target is ~/.config/$app
    if [ -e "$HOME/.config/$app" ] && [ ! -L "$HOME/.config/$app" ]; then
        echo "⚠️  Found existing config for $app, removing..."
        rm -rf "$HOME/.config/$app"
    fi

    stow "$app"
done

# --- Post-Install Hooks ---
echo "🔄 Reloading desktop environment..."

# 1. Reload i3 (Restarts in place without closing your apps)
if pgrep -x "i3" > /dev/null; then
    echo "Restarting i3..."
    i3-msg restart > /dev/null
fi

# 2. Restart Polybar
if pgrep -x "polybar" > /dev/null; then
    echo "Restarting polybar..."
    # Killing it usually triggers your i3 config to respawn it, 
    # or you can replace this with your specific launch script if you have one.
    killall polybar
fi

# 3. Restart Picom (Compositor)
if pgrep -x "picom" > /dev/null; then
    echo "Restarting picom..."
    killall picom
    # Disown detaches it from the script so it keeps running
    picom -b & disown 
fi

echo "🎉 All done! Your new dotfiles are linked and active."
