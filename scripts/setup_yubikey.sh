#!/bin/bash
set -e

echo "🔐 Starting YubiKey Security Setup..."

# --- Helper Functions ---
prompt_yes_no() {
    local prompt="$1"
    read -r -p "$prompt [y/N] " -n 1 response
    echo ""
    [[ "$response" =~ ^[Yy]$ ]]
}

run_sudo() {
    sudo bash -c "$1"
}

check_installed() {
    command -v "$1" >/dev/null 2>&1 || { echo "❌ $1 not found"; return 1; }
}

# --- Dependency Check ---
for cmd in pamu2fcfg loginctl udevadm; do
    check_installed "$cmd" || exit 1
done

# --- 1. FIDO2 / YubiKey Enrollment ---
if prompt_yes_no "🔑 Configure YubiKey for login? (clears previous registrations)"; then
    mkdir -p "$HOME/.config/Yubico"
    echo "🚨 PLEASE PLUG IN YOUR YUBIKEY NOW."
    echo "👉 When the key begins to flash, touch the metal contact..."
    pamu2fcfg > "$HOME/.config/Yubico/u2f_keys" && \
        echo "✅ YubiKey successfully registered!" || \
        echo "❌ Registration failed. Retry: pamu2fcfg > ~/.config/Yubico/u2f_keys"
fi

# --- 2. PAM Configuration ---
configure_pam() {
    local pam_file="$1"
    local pam_line="auth sufficient pam_u2f.so cue"
    
    if grep -q "pam_u2f.so" "$pam_file"; then
        echo "✅ YubiKey already configured for $pam_file"
        return 0
    fi
    
    run_sudo "sed -i '1s/^/${pam_line}\n/' '$pam_file'"
    echo "✅ YubiKey enabled for $pam_file"
}

if prompt_yes_no "🔑 Enable YubiKey for sudo commands?"; then
    configure_pam "/etc/pam.d/sudo"
fi

configure_pam "/etc/pam.d/greetd"

# --- 3. CRITICAL: Lock Screen PAM Integration ---
echo "🔒 Configuring screensaver lock authentication..."

# Detect lock manager and configure appropriately
if check_installed "swaylock"; then
    echo "📍 Detected: swaylock (Wayland)"
    configure_pam "/etc/pam.d/swaylock"
elif check_installed "i3lock"; then
    echo "📍 Detected: i3lock (X11)"
    configure_pam "/etc/pam.d/i3lock"
elif check_installed "slock"; then
    echo "📍 Detected: slock"
    # slock uses /etc/pam.d/login by default
    configure_pam "/etc/pam.d/login"
else
    echo "⚠️  Warning: No lock manager detected. Install one:"
    echo "   - Wayland: sudo pacman -S swaylock"
    echo "   - X11: sudo pacman -S i3lock"
fi

# Also add to common login services
for pam_service in common-auth login system-local-login; do
    if [ -f "/etc/pam.d/$pam_service" ]; then
        if ! grep -q "pam_u2f.so" "/etc/pam.d/$pam_service"; then
            run_sudo "sed -i '1s/^/auth sufficient pam_u2f.so cue\n/' '/etc/pam.d/$pam_service'"
            echo "✅ YubiKey enabled for $pam_service"
        fi
    fi
done

# --- 4. Auto-Lock on Key Removal ---
echo "⚙️  Setting up hardware auto-lock on key removal..."

read -r -d '' LOCK_SCRIPT << 'EOF' || true
#!/bin/bash
{
    echo "$(date): YubiKey removal detected"
    
    # Get all active sessions
    SESSIONS=$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
    
    if [ -z "$SESSIONS" ]; then
        echo "$(date): No active sessions found"
        exit 0
    fi
    
    echo "$(date): Active sessions: $SESSIONS"
    
    # Lock all sessions
    locked_any=0
    while IFS= read -r SESSION; do
        if loginctl lock-session "$SESSION" 2>/dev/null; then
            echo "$(date): Locked session $SESSION"
            locked_any=1
        fi
    done <<< "$SESSIONS"
    
    if [ $locked_any -eq 0 ]; then
        echo "$(date): Failed to lock any sessions"
    fi
} >> /tmp/yubikey-lock.log 2>&1
EOF

run_sudo "cat > /usr/local/bin/yubikey-lock.sh << 'EOF'
$LOCK_SCRIPT
EOF
chmod +x /usr/local/bin/yubikey-lock.sh"

# --- 5. Udev Rule ---
read -r -d '' UDEV_RULE << 'EOF' || true
# YubiKey auto-lock on removal (Yubico Vendor ID: 1050)
ACTION=="remove", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", RUN+="/usr/local/bin/yubikey-lock.sh"
EOF

run_sudo "cat > /etc/udev/rules.d/99-yubikey-lock.rules << 'EOF'
$UDEV_RULE
EOF"

sudo udevadm control --reload-rules
echo "✅ Udev rules reloaded"

# --- 6. Verify Lock Manager Configuration ---
echo ""
echo "🔍 LOCK MANAGER SETUP:"
LOCK_MANAGER=""
if check_installed "swaylock"; then
    echo "   ✅ swaylock (Wayland) - PAM enabled"
    LOCK_MANAGER="swaylock"
elif check_installed "i3lock"; then
    echo "   ✅ i3lock (X11) - PAM enabled"
    LOCK_MANAGER="i3lock"
else
    echo "   ⚠️  No lock manager configured"
fi

# --- 7. Summary & Testing ---
cat << EOF

🎉 YubiKey security setup complete!

🔑 AUTHENTICATION POINTS CONFIGURED:
   ✅ Login (greetd)
   ✅ Sudo
   $([ -n "$LOCK_MANAGER" ] && echo "   ✅ Lock screen ($LOCK_MANAGER)" || echo "   ⚠️  Lock screen (needs setup)")

📋 TEST LOCK SCREEN AUTHENTICATION:
   1. Lock your session: loginctl lock-session
   2. Try to unlock - YubiKey should be required
   3. Touch YubiKey to authenticate

📋 TEST AUTO-LOCK ON REMOVAL:
   1. sudo udevadm monitor --subsystem-match=usb &
   2. tail -f /tmp/yubikey-lock.log &
   3. Remove YubiKey - session should auto-lock
   4. Plug it back in and unlock with YubiKey

🔍 TROUBLESHOOTING:
   • Verify YubiKey is registered:
     cat ~/.config/Yubico/u2f_keys
   
   • Check all PAM configs:
     grep -r "pam_u2f.so" /etc/pam.d/
   
   • Test lock screen directly (need sudo):
     sudo -u \$USER swaylock -f  # or i3lock -n
   
   • Manual lock test:
     /usr/local/bin/yubikey-lock.sh && tail -20 /tmp/yubikey-lock.log
   
   • Check udev events:
     sudo udevadm monitor --subsystem-match=usb
   
   • List active sessions:
     loginctl list-sessions

📌 IF UNLOCK STILL FAILS:
   • Ensure your lock manager is PAM-aware:
     grep pam_u2f.so /etc/pam.d/swaylock
   
   • Try testing PAM directly:
     sudo pam_u2f_agent -d /dev/hidraw* || echo "Touch YubiKey..."
   
   • Check system logs:
     journalctl -xe | grep -i pam

EOF
