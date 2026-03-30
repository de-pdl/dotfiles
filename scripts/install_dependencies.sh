#!/bin/bash

echo "📦 Starting Wayland/Sway dependency installation..."

# Ensure system is up to date first
echo "🔄 Updating system..."
sudo pacman -Syu --noconfirm

# --- 1. Official Arch Packages ---
PACMAN_PKGS=(
    # Core Wayland & Window Manager
    sway swaybg swaylock swayidle
    
    # Login Manager (Display Manager)
    greetd greetd-tuigreet

    # gpu check
    pciutils
    
    # Hardware Security (YubiKey)
    pam-u2f

    # Wayland Screen Sharing & Portals
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    pipewire wireplumber
    slurp grim wl-clipboard

    # UI Components & Utilities
    waybar alacritty neovim
    dunst gammastep kanshi
    
    # Fonts
    ttf-jetbrains-mono-nerd ttf-hack-nerd
)

echo "📥 Installing official Arch packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# --- 2. Install AUR Helper (yay) if missing ---
if ! command -v yay &> /dev/null; then
    echo "🔍 yay not found. Installing from AUR..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit
    makepkg -si --noconfirm
    cd - || exit
    rm -rf /tmp/yay
    echo "✅ yay installed successfully!"
else
    echo "✅ yay is already installed."
fi

# --- 3. AUR Packages ---
AUR_PKGS=(
    rofi-wayland       # Wayland native app launcher
    matugen-bin        # Material colors generator
    # vesktop-bin      # Uncomment if you want the Wayland-fixed Discord client
)

echo "📥 Installing AUR packages..."
# Run yay without sudo (yay handles privilege escalation internally)
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

echo "🎉 All dependencies installed successfully!"
