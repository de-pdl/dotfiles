#!/bin/bash
# Gaming Mode install: network-priority service + sudoers rule + updated toggle.
# Run once on cronos:  bash ~/.config/scripts/rice_farm/scripts/install-gaming-net.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo (needs root for service install):"; echo "  sudo bash $0"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="${SUDO_USER:-ayush}"

# 1. network script + systemd service (root-owned)
install -m 755 "$DIR/gaming-net.sh" /usr/local/sbin/gaming-net
install -m 644 "$DIR/gaming-net.service" /etc/systemd/system/gaming-net.service
systemctl daemon-reload

# 2. sudoers: passwordless governor + gaming-net service control
SUDOERS_FILE=/etc/sudoers.d/rice-gaming
cat > "$SUDOERS_FILE" <<EOF
$USER_NAME ALL=(root) NOPASSWD: /usr/bin/cpupower frequency-set -g performance, /usr/bin/cpupower frequency-set -g powersave, /usr/bin/systemctl start gaming-net, /usr/bin/systemctl stop gaming-net
EOF
chown root:root "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE"

# 3. sanity: apply rules now to verify nft syntax on this kernel
systemctl start gaming-net
nft list table inet gamemode >/dev/null && echo "nft table OK"
systemctl stop gaming-net

echo
echo "All done. Toggle Gaming Mode from the rofi menu — governor, llama kill,"
echo "and network priority now all fire without a password."
