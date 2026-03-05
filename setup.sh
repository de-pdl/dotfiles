#!/bin/bash

echo "🚀 Starting Arch Linux dotfiles setup prerequisites..."

# 1. Install core setup tools and fonts
echo "📦 Installing core prerequisites (stow, git, base-devel, fonts)..."
sudo pacman -Syu --needed --noconfirm stow git base-devel ttf-jetbrains-mono-nerd

# 2. Install yay (AUR Helper)
echo "🔍 Checking for yay..."
if ! command -v yay &> /dev/null; then
    echo "📦 Installing yay from the AUR..."
    # Clone to a temporary directory, build, and clean up
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit
    makepkg -si --noconfirm
    cd - || exit
    rm -rf /tmp/yay
    echo "✅ yay installed successfully!"
else
    echo "✅ yay is already installed."
fi

# 3. Pre-create target directories
echo "📁 Creating base directories..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"

# 4. Basic Git Setup (Interactive)
echo "🐙 Checking Git configuration..."
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter Git User Name: " git_name
    git config --global user.name "$git_name"
fi
if [ -z "$(git config --global user.email)" ]; then
    read -p "Enter Git Email: " git_email
    git config --global user.email "$git_email"
fi

# 5. Make the install script executable automatically
chmod +x "$(dirname "$0")/install.sh"

echo "✅ Setup complete! You can now run ./install.sh"

# --- Setup Git Hooks ---
echo "🪝 Setting up Git post-merge hook..."
HOOK_DIR="$(pwd)/.git/hooks"
HOOK_FILE="$HOOK_DIR/post-merge"

if [ -d "$HOOK_DIR" ]; then
    cat << 'EOF' > "$HOOK_FILE"
#!/bin/bash
echo "🔄 Git pull detected! Syncing dotfiles..."
REPO_DIR=$(git rev-parse --show-toplevel)
if [ -f "$REPO_DIR/install.sh" ]; then
    "$REPO_DIR/install.sh"
fi
EOF
    chmod +x "$HOOK_FILE"
    echo "✅ Git hook configured!"
fi
