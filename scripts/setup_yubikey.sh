#!/bin/bash

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

# --- 4. Portable Auto-Lock (Removal) ---
echo "⚙️  Setting up hardware auto-lock on key removal..."

cat << 'EOF' | sudo tee /usr/local/bin/yubikey-lock.sh > /dev/null
#!/bin/bash
ACTIVE_USER=$(loginctl list-sessions --no-legend | awk '$5=="active" {print $3}' | head -n 1)
if [ -z "$ACTIVE_USER" ]; then exit 0; fi 

USER_ID=$(id -u "$ACTIVE_USER")
W_DISP=$(ls /run/user/$USER_ID | grep -m 1 '^wayland-[0-9]\+$')

su - "$ACTIVE_USER" -c "env XDG_RUNTIME_DIR=/run/user/$USER_ID WAYLAND_DISPLAY=$W_DISP swaylock -f -c 000000"
EOF

sudo chmod +x /usr/local/bin/yubikey-lock.sh
echo 'ACTION=="remove", ENV{ID_VENDOR_ID}=="1050", RUN+="/usr/local/bin/yubikey-lock.sh"' | sudo tee /etc/udev/rules.d/99-yubikey-lock.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger

echo "🎉 YubiKey security setup complete!"
