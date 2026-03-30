#!/bin/bash
set -e

echo "🔐 Starting YubiKey Security Setup..."

# --- 1. FIDO2 / YubiKey Enrollment ---
echo "🔑 Do you want to configure a YubiKey for login right now?"
echo "   (WARNING: This clears any previously registered keys for this user) [y/N]"
read -r -n 1 setup_yubikey
echo ""
if [[ "$setup_yubikey" =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/.config/Yubico"
    echo "🚨 PLEASE PLUG IN YOUR YUBIKEY NOW."
    echo "👉 When the key begins to flash, touch the metal contact..."
    if pamu2fcfg > "$HOME/.config/Yubico/u2f_keys"; then
        echo "✅ YubiKey successfully registered!"
    else
        echo "❌ Registration failed. Run 'pamu2fcfg > ~/.config/Yubico/u2f_keys' later."
    fi
fi

# --- 2. Sudo Injection ---
echo "🔑 Do you want to enable YubiKey for 'sudo' commands? [y/N]"
read -r -n 1 setup_sudo
echo ""
if [[ "$setup_sudo" =~ ^[Yy]$ ]]; then
    if ! grep -q "pam_u2f.so" /etc/pam.d/sudo; then
        sudo sed -i '1s/^/auth sufficient pam_u2f.so cue\n/' /etc/pam.d/sudo
        echo "✅ Sudo will now ask for your YubiKey!"
    else
        echo "✅ YubiKey is already configured for sudo."
    fi
fi

# --- 3. Greetd (Login Manager) Injection ---
echo "🔑 Enabling YubiKey login for Greetd..."
if ! grep -q "pam_u2f.so" /etc/pam.d/greetd; then
    sudo sed -i '1s/^/auth sufficient pam_u2f.so cue\n/' /etc/pam.d/greetd
    echo "✅ YubiKey support added to greetd."
fi

# --- 4. Portable Auto-Lock (YubiKey Removal Detection) ---
echo "⚙️  Setting up hardware auto-lock on key removal..."

# Deploy the lock script - use loginctl instead of su
sudo bash -c 'cat << '\''EOF'\'' > /usr/local/bin/yubikey-lock.sh
#!/bin/bash
{
    echo "$(date): YubiKey removal detected"
    
    # Get the active session
    SESSION=$(loginctl list-sessions --no-legend | awk '\''NR==1 {print $1}'\'')
    echo "$(date): Active session: $SESSION"
    
    if [ -z "$SESSION" ]; then
        echo "$(date): No active session found"
        exit 0
    fi
    
    # Lock the session directly using loginctl
    if loginctl lock-session "$SESSION" 2>/dev/null; then
        echo "$(date): Successfully locked session $SESSION"
    else
        echo "$(date): Failed to lock session $SESSION, trying alternative..."
        # Fallback: try to lock all sessions
        loginctl list-sessions --no-legend | awk '\''{print $1}'\'' | while read sess; do
            loginctl lock-session "$sess" 2>/dev/null || true
        done
        echo "$(date): Attempted to lock all sessions"
    fi
} >> /tmp/yubikey-lock.log 2>&1
EOF
'
sudo chmod +x /usr/local/bin/yubikey-lock.sh

# --- 5. Deploy Udev Rule ---
echo "Setting up udev rule for YubiKey detection..."
sudo bash -c 'cat << '\''EOF'\'' > /etc/udev/rules.d/99-yubikey-lock.rules
# YubiKey auto-lock on removal (Yubico Vendor ID: 1050)
ACTION=="remove", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", RUN+="/usr/local/bin/yubikey-lock.sh"
EOF
'

# Reload udev rules
sudo udevadm control --reload-rules
echo "✅ Udev rules reloaded"

# --- 6. Manual Test Instructions ---
echo ""
echo "🎉 YubiKey security setup complete!"
echo ""
echo "📋 To test auto-lock functionality:"
echo "   1. Open a new terminal"
echo "   2. Run: sudo udevadm monitor --subsystem-match=usb"
echo "   3. In another terminal, run: tail -f /tmp/yubikey-lock.log"
echo "   4. Remove your YubiKey and watch the logs"
echo ""
echo "🔍 If auto-lock still doesn't work:"
echo "   1. Check your YubiKey vendor ID:"
echo "      lsusb | grep -i yubico"
echo "   2. Verify the udev rule:"
echo "      cat /etc/udev/rules.d/99-yubikey-lock.rules"
echo "   3. Check the lock script:"
echo "      cat /usr/local/bin/yubikey-lock.sh"
echo "   4. Manual lock test:"
echo "      /usr/local/bin/yubikey-lock.sh && cat /tmp/yubikey-lock.log"
echo ""
