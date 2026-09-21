#!/bin/bash
# gaming-net: DSCP-mark game traffic for WMM priority over the wifi hop.
# Installed as root systemd service; started/stopped by the rice_farm
# Gaming Mode toggle.
#
# Why: cronos is on wifi; the first-hop AP airtime is the jitter source.
# DSCP EF/CS5 maps to WMM video/voice queues on UniFi, which the AP
# schedules ahead of background traffic from other clients.
#
# Mark rules (IPv4 outbound):
#   UDP sport 27015-27050 (CS2/Steam game traffic)  -> EF
#   UDP dport 27015-27050                           -> EF
#   UDP dport 3478-3479, 51888 (Steam voice)        -> CS5
set -euo pipefail

ensure_table() {
    # idempotent table creation
    if ! nft list table inet gamemode >/dev/null 2>&1; then
        nft add table inet gamemode
        nft add chain inet gamemode mangle_out '{ type filter hook output priority -150; policy accept; }'
        # numeric DSCP: 46=EF (voice), 40=CS5 (video); symbolic names not
        # accepted by this nft version
        nft add rule inet gamemode mangle_out meta nfproto ipv4 udp sport 27015-27050 ip dscp set 46
        nft add rule inet gamemode mangle_out meta nfproto ipv4 udp dport 27015-27050 ip dscp set 46
        nft add rule inet gamemode mangle_out meta nfproto ipv4 udp dport 3478-3479 ip dscp set 40
        nft add rule inet gamemode mangle_out meta nfproto ipv4 udp dport 51888 ip dscp set 40
    fi
}

case "${1:-}" in
    start)
        ensure_table
        echo "gamemode nft rules applied"
        ;;
    stop)
        nft delete table inet gamemode 2>/dev/null || true
        echo "gamemode nft rules removed"
        ;;
    status)
        nft list table inet gamemode 2>/dev/null || echo "inactive"
        ;;
esac
