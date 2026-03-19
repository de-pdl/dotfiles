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
echo "Installing: tree-sitter, npm for tree-sitter parser..."
sudo apt-get install -y \
    tree-sitter-cli \
    nodejs \
    npm


# === General LSP/Formatting ===
echo ""
echo "### General Development"
echo "Installing: git, curl, build-essential..."
sudo apt-get install -y \
    git \
    curl \
    build-essential

# === Optional: Language Servers ===
echo ""
echo "### Language Servers (Optional)"
read -p "Install Python LSP (pylsp)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt-get install -y python3-pylsp
fi

read -p "Install Rust analyzer? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - | sudo mv /dev/stdin /usr/local/bin/rust-analyzer
    sudo chmod +x /usr/local/bin/rust-analyzer
fi

echo "✅ Debian installation complete!"
