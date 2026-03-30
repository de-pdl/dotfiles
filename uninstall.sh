#!/bin/bash

echo "🗑️  Starting dotfiles uninstallation (unlinking)..."
echo "⚠️  This will NOT remove the actual installed packages from your system."
echo "It will only remove the symlinks created by Stow in your home directory."
echo ""

# Add a safety prompt
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Uninstallation aborted."
    exit 1
fi

# Navigate to the dotfiles directory safely
cd "$(dirname "$0")" || exit 1

# List of folders to unstow
apps=(
    "scripts"
    "nvim"
    "alacritty"
    "i3"
    "polybar"
    "picom"
    "matugen"
)

# --- Execution ---
for app in "${apps[@]}"; do
    echo "✂️  Unstowing $app..."
    # The -D flag tells stow to delete the symlinks
    stow -D "$app"
done

echo "✅ All dotfile symlinks have been removed!"
echo "Your system will now fall back to default configurations (you may need to restart your apps/shell)."
