#!/bin/bash

echo "🚀 Starting Arch Linux (Wayland/Sway) setup prerequisites..."

# 👉 NEW: Removed 'stow', added 'greetd', 'tuigreet', 'pam-u2f' and Waybar's Hack Nerd font
echo "📦 Installing core prerequisites..."
sudo pacman -Syu --needed --noconfirm git base-devel ttf-jetbrains-mono-nerd ttf-hack-nerd greetd greetd-tuigreet pam-u2f

# 2. Install yay (AUR Helper)
echo "🔍 Checking for yay..."
if ! command -v yay &> /dev/null; then
    echo "📦 Installing yay from the AUR..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit
    makepkg -si --noconfirm
    cd - || exit
    rm -rf /tmp/yay
    echo "✅ yay installed successfully!"
else
    echo "✅ yay is already installed."
fi

# 👉 NEW: Configure greetd to launch Sway automatically
echo "⚙️  Configuring greetd (Login Manager)..."
# Back up the original config just in case
sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.bak
# Replace the default greetd command with tuigreet launching sway
sudo sed -i 's|^command = .*|command = "tuigreet --time --cmd sway"|' /etc/greetd/config.toml

# --- Module Execution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

# Call the YubiKey setup script
if [ -f "$SCRIPT_DIR/setup_yubikey.sh" ]; then
    chmod +x "$SCRIPT_DIR/setup_yubikey.sh"
    "$SCRIPT_DIR/setup_yubikey.sh"
else
    echo "⚠️  Could not find setup_yubikey.sh module. Skipping hardware security setup."
fi

# 👉 NEW: Swap the Display Manager (Goodbye LightDM, Hello Greetd)
echo "🔄 Switching display manager to greetd..."
sudo systemctl disable lightdm.service 2>/dev/null
sudo systemctl enable greetd.service
echo "✅ Display manager swapped! It will take effect on reboot."

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
# 👉 NEW: Stripped the stow logic, just triggers the new flat install.sh
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
