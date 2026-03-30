#!/bin/bash

set -e

echo "📦 Installing dependencies for Debian/Ubuntu"

# Update package manager
sudo apt-get update

# === Preview.lua ===
echo ""
echo "### Preview.lua"
echo "Installing: ueberzug/chafa, fzf, ripgrep, bat..."
sudo apt-get install -y \
    fzf \
    ripgrep \
    bat \
    chafa \
    python3-pip

pip3 install --user ueberzug

# === Syntax.lua ===
echo ""
echo "### Syntax.lua"
echo "Installing: tree-sitter, nodejs, npm, clang, python..."
sudo apt-get install -y \
    tree-sitter-cli \
    nodejs \
    npm \
    clang \
    python3
# === General LSP/Formatting ===
echo ""
echo "### General Development"
echo "Installing: git, curl, build-essential..."
sudo apt-get install -y \
    git \
    curl \
    build-essential
echo "✅ Debian installation complete!"
