#!/bin/bash
set -e

PROFILE="${1:-default}"

# Which sections to run based on profile
RUN_FORMATTING=true
RUN_DEBUG=false
RUN_HARDWARE=false

case "$PROFILE" in
  minimal)
    RUN_FORMATTING=false
    ;;
  default)
    ;;
  hardware)
    RUN_DEBUG=true
    RUN_HARDWARE=true
    ;;
  full)
    RUN_DEBUG=true
    RUN_HARDWARE=true
    ;;
esac

echo "📦 Installing dependencies for Arch Linux (profile: $PROFILE)"

# ─────────────────────────────────────────────────────────
# Section: Core (general dev tools, always installs)
# Used by: init.lua, build tools, git
# ─────────────────────────────────────────────────────────
echo ""
echo "### Core"
sudo pacman -S --noconfirm --needed \
  git \
  curl \
  base-devel

# ─────────────────────────────────────────────────────────
# Section: Preview
# Used by: lua/plugins/preview.lua (image/file preview, fuzzy tools)
# ─────────────────────────────────────────────────────────
echo ""
echo "### Preview"
sudo pacman -S --noconfirm --needed \
  ueberzug \
  chafa \
  fzf \
  ripgrep \
  bat

# ─────────────────────────────────────────────────────────
# Section: Syntax & LSP runtimes
# Used by: lua/plugins/syntax.lua, lua/plugins/lsp.lua
# ─────────────────────────────────────────────────────────
echo ""
echo "### Syntax & LSP runtimes"
sudo pacman -S --noconfirm --needed \
  tree-sitter-cli \
  nodejs \
  npm \
  clang \
  python

# ─────────────────────────────────────────────────────────
# Section: Navigation
# Used by: lua/plugins/navigation.lua (Telescope hidden-file search)
# ─────────────────────────────────────────────────────────
echo ""
echo "### Navigation"
sudo pacman -S --noconfirm --needed \
  fd

# ─────────────────────────────────────────────────────────
# Section: Formatting & Linting
# Used by: lua/plugins/formatting.lua
# ─────────────────────────────────────────────────────────
if [[ "$RUN_FORMATTING" == "true" ]]; then
  echo ""
  echo "### Formatting & Linting"
  sudo pacman -S --noconfirm --needed \
    stylua \
    python-black \
    python-isort \
    shfmt \
    prettier \
    shellcheck \
    cppcheck \
    markdownlint-cli
fi

# ─────────────────────────────────────────────────────────
# Section: Debug
# Used by: lua/plugins/debug.lua (Phase 7 — nvim-dap)
# ─────────────────────────────────────────────────────────
if [[ "$RUN_DEBUG" == "true" ]]; then
  echo ""
  echo "### Debug (GDB, LLDB)"
  sudo pacman -S --noconfirm --needed \
    gdb \
    lldb
fi

# ─────────────────────────────────────────────────────────
# Section: Hardware
# Used by: lua/plugins/hardware.lua (Phase 9)
# Covers: AVR, ESP32/ESP8266, Verilog/VHDL (FPGA)
# ─────────────────────────────────────────────────────────
if [[ "$RUN_HARDWARE" == "true" ]]; then
  echo ""
  echo "### Hardware (official repos)"
  sudo pacman -S --noconfirm --needed \
    arduino-cli \
    avrdude \
    avr-gcc \
    avr-libc \
    esptool \
    iverilog \
    verilator \
    yosys \
    gtkwave

  echo ""
  echo "### Hardware (AUR — Verible SystemVerilog LSP)"
  if command -v paru >/dev/null 2>&1; then
    paru -S --noconfirm --needed verible-bin
  elif command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm --needed verible-bin
  else
    echo "⚠️  No AUR helper (paru/yay) found. Skipping verible-bin."
    echo "   Install manually from: https://aur.archlinux.org/packages/verible-bin"
  fi
fi

# ─────────────────────────────────────────────────────────
# Section: MATLAB tooling
# Used by: lua/plugins/matlab.lua
# Note: MATLAB itself is NOT installed (proprietary, license-gated)
# We install only the LSP, which needs MATLAB separately for full features
# ─────────────────────────────────────────────────────────
if [[ "$RUN_FORMATTING" == "true" ]]; then
  echo ""
  echo "### MATLAB (LSP only — MATLAB itself must be installed separately)"
  sudo npm install -g matlab-language-server

  if ! command -v matlab >/dev/null 2>&1; then
    echo "⚠️  MATLAB binary not found on \$PATH."
    echo "   Install MATLAB from MathWorks, then add its bin/ to your PATH:"
    echo "     export PATH=\"/usr/local/MATLAB/R<VERSION>/bin:\$PATH\""
    echo "   The LSP will still load but without full language features."
  fi
fi

# ─────────────────────────────────────────────────────────
# Section: Verification
# ─────────────────────────────────────────────────────────
echo ""
echo "### Verifying installed tools"

check() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    echo "  ✓ $name"
  else
    echo "  ✗ $name  (missing)"
  fi
}

# Always-installed
check git
check curl
check chafa
check fzf
check rg
check bat
check tree-sitter
check node
check npm
check clang
check clangd
check python
check fd

# Profile-dependent
[[ "$RUN_FORMATTING" == "true" ]] && {
  check stylua
  check clang-format
  check black
  check isort
  check shfmt
  check prettier
  check shellcheck
  check cppcheck
  check matlab-language-server
  check matlab
  check mlint
  check markdownlint
}

[[ "$RUN_DEBUG" == "true" ]] && {
  check gdb
  check lldb
}

[[ "$RUN_HARDWARE" == "true" ]] && {
  check arduino-cli
  check avrdude
  check avr-gcc
  check esptool.py
  check iverilog
  check verilator
  check yosys
  check gtkwave
  check verible-verilog-ls
}

echo ""
echo "✅ Arch installation complete (profile: $PROFILE)"
