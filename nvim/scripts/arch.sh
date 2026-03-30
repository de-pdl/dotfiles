#!/bin/bash

set -e

echo "📦 Installing dependencies for Arch Linux"

# === Preview.lua ===
echo ""
echo "### Preview.lua"
echo "Installing: ueberzug/chafa, fzf, ripgrep, bat..."
sudo pacman -S --noconfirm \
    ueberzug \
    chafa \
    fzf \
    ripgrep \
    bat

# === Syntax.lua ===
echo ""
echo "### Syntax.lua"
echo "Installing: tree-sitter, nodejs, npm, clang, python..."
sudo pacman -S --noconfirm \
    tree-sitter-cli \
    nodejs \
    npm \
    clang \
    python
# === General LSP/Formatting ===
echo ""
echo "### General Development"
echo "Installing: git, curl, build-essential..."
sudo pacman -S --noconfirm \
    git \
    curl \
    base-devel
echo "✅ Arch installation complete!"
