#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS=""
PROFILE="default"

usage() {
    cat <<EOF
Usage: $0 [PROFILE]

Profiles:
  --minimal    Core editor tools only (treesitter, preview, syntax)
  (default)    Minimal + formatters/linters
  --hardware   Default + debug + embedded/HDL toolchain
  --full       Everything

Examples:
  $0                  # default install
  $0 --minimal        # bare minimum
  $0 --hardware       # full embedded dev setup
  $0 --full           # kitchen sink

EOF
    exit 0
}

parse_args() {
    case "${1:-}" in
        --minimal)  PROFILE="minimal" ;;
        --hardware) PROFILE="hardware" ;;
        --full)     PROFILE="full" ;;
        -h|--help)  usage ;;
        "")         PROFILE="default" ;;
        *)
            echo "❌ Unknown argument: $1"
            usage
            ;;
    esac
}

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
    echo "✓ Profile:     $PROFILE"
}

run_installer() {
    case $OS in
        arch)   bash "$SCRIPT_DIR/arch.sh"   "$PROFILE" ;;
        debian) bash "$SCRIPT_DIR/debian.sh" "$PROFILE" ;;
    esac
}

main() {
    echo "🚀 Neovim Setup Installer"
    parse_args "$@"
    detect_os
    run_installer
    echo ""
    echo "✅ Installation complete!"
}

main "$@"
