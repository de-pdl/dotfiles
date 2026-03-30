#!/bin/bash

set -e

OS=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_os() {
    if [[ -f /etc/arch-release ]]; then
        OS="arch"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
    else
        echo "❌ Unsupported OS"
        exit 1
    fi
    echo "✓ Detected OS: $OS"
}

run_installer() {
    case $OS in
        arch)
            bash "$SCRIPT_DIR/arch.sh"
            ;;
        debian)
            bash "$SCRIPT_DIR/debian.sh"
            ;;
    esac
}

main() {
    echo "🚀 Neovim Setup Installer"
    detect_os
    run_installer
    echo "✅ Installation complete!"
}

main "$@"
