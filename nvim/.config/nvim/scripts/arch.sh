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
echo "Installing: tree-sitter, npm for tree-sitter parser..."
sudo pacman -S --noconfirm \
    tree-sitter-cli\
    nodejs \
    npm


# === General LSP/Formatting ===
echo ""
echo "### General Development"
echo "Installing: git, curl, build-essential..."
sudo pacman -S --noconfirm \
    git \
    curl \
    base-devel

# === Optional: Language Servers ===
echo ""
echo "### Language Servers (Optional)"
read -p "Install Python LSP (pylsp)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S --noconfirm python-lsp-server
fi

read -p "Install Rust analyzer? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S --noconfirm rust-analyzer
fi

echo "✅ Arch installation complete!"
