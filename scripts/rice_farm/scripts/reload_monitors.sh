#!/bin/bash
# scripts/reload_monitors.sh
set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kill kanshi and restart it to force config reload
pkill kanshi 2>/dev/null || true
sleep 0.5

# Start kanshi fresh
kanshi &
sleep 1  # Give it time to apply profile

# Refresh background
if [[ -f "$script_dir/bg_load.sh" ]]; then
    "$script_dir/bg_load.sh" &
else
    echo "Error: bg_load.sh not found"
    exit 1
fi
