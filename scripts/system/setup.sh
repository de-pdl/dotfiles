#!/bin/bash

echo "🚀 Starting Arch Linux (Wayland/Sway) system configuration..."
echo "⚠️  Ensure you have run ./install_dependencies.sh first!"
echo ""

# 1. Configure greetd to launch Sway automatically
echo "⚙️  Configuring greetd (Login Manager)..."
# Back up the original config just in case
sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.bak

# Replace the default greetd command with tuigreet launching sway
# 🔍 Detect if an NVIDIA GPU is physically present
if lspci | grep -iq "nvidia"; then
    echo "🏎️  NVIDIA GPU detected! Adding --unsupported-gpu flag to Greetd..."
    # We use single quotes inside the double quotes for tuigreet's --cmd
    GREETD_CMD="tuigreet --time --cmd 'sway --unsupported-gpu'"
else
    echo "🖥️  Non-NVIDIA GPU detected. Using standard Sway command."
    GREETD_CMD="tuigreet --time --cmd sway"
fi

# Apply the detected command to the config
sudo sed -i "s|^command = .*|command = \"$GREETD_CMD\"|" /etc/greetd/config.toml

# 2. Module Execution (Hardware Security)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

# Call the YubiKey setup script
if [ -f "$SCRIPT_DIR/setup_yubikey.sh" ]; then
    chmod +x "$SCRIPT_DIR/setup_yubikey.sh"
    "$SCRIPT_DIR/setup_yubikey.sh"
else
    echo "⚠️  Could not find setup_yubikey.sh module. Skipping hardware security setup."
fi

# 3. Swap the Display Manager (Goodbye LightDM, Hello Greetd)
echo "🔄 Switching display manager to greetd..."
sudo systemctl disable lightdm.service 2>/dev/null
sudo systemctl enable greetd.service
echo "✅ Display manager swapped! It will take effect on reboot."

# 4. Pre-create target directories
echo "📁 Creating base directories..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"

# 5. Basic Git Setup (Interactive)
echo "🐙 Checking Git configuration..."
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter Git User Name: " git_name
    git config --global user.name "$git_name"
fi
if [ -z "$(git config --global user.email)" ]; then
    read -p "Enter Git Email: " git_email
    git config --global user.email "$git_email"
fi

# 6. Make the install script executable automatically
chmod +x "$(dirname "$0")/install.sh"

# 7. Setup Git Hooks
echo "🪝 Setting up Git post-merge hook..."
HOOK_DIR="$(pwd)/.git/hooks"
HOOK_FILE="$HOOK_DIR/post-merge"

if [ -d "$HOOK_DIR" ]; then
    cat << 'EOF' > "$HOOK_FILE"
#!/bin/bash
echo "🔄 Git pull detected! Syncing dotfiles..."
REPO_DIR=$(git rev-parse --show-toplevel)
if [ -f "$REPO_DIR/scripts/system/install.sh" ]; then
    "$REPO_DIR/scripts/system/install.sh"
fi
EOF
    chmod +x "$HOOK_FILE"
    echo "✅ Git hook configured!"
fi

echo ""
echo "🎉 System configuration complete! You can now run ./scripts/system/install.sh to link your dotfiles."
