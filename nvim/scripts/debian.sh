#!/bin/bash
set -e

PROFILE="${1:-default}"

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

echo "📦 Installing dependencies for Debian/Ubuntu (profile: $PROFILE)"

sudo apt-get update

# ─────────────────────────────────────────────────────────
# Section: Core
# ─────────────────────────────────────────────────────────
echo ""
echo "### Core"
sudo apt-get install -y \
    git \
    curl \
    build-essential

# ─────────────────────────────────────────────────────────
# Section: Preview
# ─────────────────────────────────────────────────────────
echo ""
echo "### Preview"
sudo apt-get install -y \
    chafa \
    fzf \
    ripgrep \
    bat
# Note: `bat` binary is called `batcat` on Debian — some users symlink it.
# Note: ueberzug not in apt — install via pipx if needed:
#   pipx install ueberzug

# ─────────────────────────────────────────────────────────
# Section: Syntax & LSP runtimes
# ─────────────────────────────────────────────────────────
echo ""
echo "### Syntax & LSP runtimes"
sudo apt-get install -y \
    nodejs \
    npm \
    clang \
    clangd \
    python3 \
    python3-pip

# tree-sitter-cli not in apt — install via npm
if ! command -v tree-sitter >/dev/null 2>&1; then
    echo "Installing tree-sitter-cli via npm..."
    sudo npm install -g tree-sitter-cli
fi

# ─────────────────────────────────────────────────────────
# Section: Navigation
# ─────────────────────────────────────────────────────────
echo ""
echo "### Navigation"
sudo apt-get install -y fd-find
# Note: Debian names the binary `fdfind`. Symlink it to `fd` for Telescope:
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    mkdir -p ~/.local/bin
    ln -sf "$(command -v fdfind)" ~/.local/bin/fd
    echo "  Symlinked fdfind → ~/.local/bin/fd"
fi

# ─────────────────────────────────────────────────────────
# Section: Formatting & Linting
# ─────────────────────────────────────────────────────────
if [[ "$RUN_FORMATTING" == "true" ]]; then
    echo ""
    echo "### Formatting & Linting"
    sudo apt-get install -y \
        black \
        isort \
        shfmt \
        shellcheck \
        cppcheck \
        clang-format

    # npm-based tools (not reliably in apt)
    sudo npm install -g \
        prettier \
        markdownlint-cli

    # stylua: not in apt, not in npm — install via cargo if available
    if ! command -v stylua >/dev/null 2>&1; then
        if command -v cargo >/dev/null 2>&1; then
            echo "Installing stylua via cargo..."
            cargo install stylua
        else
            echo "⚠️  stylua: install cargo first, then: cargo install stylua"
            echo "    (apt install cargo, or use rustup)"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────
# Section: Debug
# ─────────────────────────────────────────────────────────
if [[ "$RUN_DEBUG" == "true" ]]; then
    echo ""
    echo "### Debug (GDB, LLDB)"
    sudo apt-get install -y \
        gdb \
        lldb
fi

# ─────────────────────────────────────────────────────────
# Section: Hardware
# ─────────────────────────────────────────────────────────
if [[ "$RUN_HARDWARE" == "true" ]]; then
    echo ""
    echo "### Hardware (AVR + FPGA from apt)"
    sudo apt-get install -y \
        avrdude \
        gcc-avr \
        avr-libc \
        iverilog \
        verilator \
        yosys \
        gtkwave

    # esptool via pip
    echo ""
    echo "### Hardware (ESP tools via pip)"
    pip3 install --user --break-system-packages esptool 2>/dev/null \
        || pip3 install --user esptool

    # arduino-cli: not in apt, official install script
    if ! command -v arduino-cli >/dev/null 2>&1; then
        echo ""
        echo "### Hardware (arduino-cli via official install script)"
        mkdir -p ~/.local/bin
        curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
            | BINDIR=~/.local/bin sh
    fi

    # Verible: not in apt, fetch prebuilt from GitHub releases
    if ! command -v verible-verilog-ls >/dev/null 2>&1; then
        echo ""
        echo "### Hardware (Verible SystemVerilog LSP via GitHub release)"
        VERIBLE_VER="v0.0-3828-g83fa4e1e"
        TMPDIR="$(mktemp -d)"
        curl -fsSL \
            "https://github.com/chipsalliance/verible/releases/download/${VERIBLE_VER}/verible-${VERIBLE_VER}-linux-static-x86_64.tar.gz" \
            -o "$TMPDIR/verible.tar.gz" \
            && tar -xzf "$TMPDIR/verible.tar.gz" -C "$TMPDIR" \
            && mkdir -p ~/.local/bin \
            && cp "$TMPDIR/verible-${VERIBLE_VER}/bin/"* ~/.local/bin/ \
            && rm -rf "$TMPDIR" \
            || echo "⚠️  Verible install failed — install manually from https://github.com/chipsalliance/verible/releases"
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

check git
check curl
check chafa
check fzf
check rg
check tree-sitter
check node
check npm
check clang
check clangd
check python3
check fd

[[ "$RUN_FORMATTING" == "true" ]] && {
    check stylua
    check clang-format
    check black
    check isort
    check shfmt
    check prettier
    check shellcheck
    check cppcheck
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
echo "✅ Debian installation complete (profile: $PROFILE)"
echo ""
echo "ℹ️  If ~/.local/bin isn't in your PATH, add this to ~/.bashrc or ~/.zshrc:"
echo '    export PATH="$HOME/.local/bin:$PATH"'
