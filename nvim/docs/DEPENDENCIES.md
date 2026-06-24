# Plugin Dependencies

All dependencies are installed automatically by `scripts/install.sh`, which
auto-detects Arch or Debian and calls the correct sub-script.

## Install Profiles

| Profile | What's installed |
|---------|------------------|
| `--minimal` | Core + Preview + Syntax + Navigation |
| *(default)* | Minimal + Formatting & Linting |
| `--hardware` | Default + Debug + Hardware toolchain |
| `--full` | Everything |

```bash
./scripts/install.sh              # default
./scripts/install.sh --minimal    # bare minimum
./scripts/install.sh --hardware   # full embedded dev setup
./scripts/install.sh --full       # kitchen sink
```

---

## Preview.lua

**Purpose:** Image/media preview in floating windows

### Required
- `ueberzug` or `chafa` - Image rendering
- `fzf` - Fuzzy finder
- `ripgrep` - Fast search
- `bat` - Syntax highlighted cat

### Installation
**Arch:** Already in arch.sh
**Debian:** Already in debian.sh (note: `ueberzug` not in apt — install via
`pipx install ueberzug` if you need it)

---

## Syntax.lua

**Purpose:** Syntax highlighting with Tree-sitter

### Required
- `tree-sitter-cli` - Parser library
- `nodejs` + `npm` - For TSUpdate command
- `clang` - C
- `python3` - Python

### Installation
**Arch:** Already in arch.sh
**Debian:** Already in debian.sh (tree-sitter-cli installed via `npm -g` — not
available in apt)

---

## Lsp.lua

**Purpose:** Language Server Protocol support

### Required
- `clangd` - C/C++ language server (ships with `clang`)
- `nodejs` + `npm` - Runtime for JS-based LSPs (pyright, bashls, etc.)
- `python3` - Python runtime

### Managed by Mason (auto-installs)
- `pyright` - Python
- `lua_ls` - Lua
- `bashls` - Bash
- `html`, `cssls`, `jsonls`, `yamlls` - Web/config files
- `taplo` - TOML
- `marksman` - Markdown

### Installation
**Arch:** Already in arch.sh
**Debian:** Already in debian.sh

---

## Navigation.lua

**Purpose:** Telescope fuzzy finder + Neo-tree file explorer

### Required
- `fd` - Fast file finder (Telescope hidden-file search)
- `ripgrep` - Live grep backend (already required by Preview)

### Installation
**Arch:** Already in arch.sh (package: `fd`)
**Debian:** Already in debian.sh (package: `fd-find`, binary named `fdfind`
— the script symlinks it to `~/.local/bin/fd`)

---

## Formatting.lua

**Purpose:** Format-on-save via conform.nvim + linters via nvim-lint

### Required
- `stylua` - Lua formatter
- `clang-format` - C/C++ formatter (ships with `clang`)
- `black` - Python formatter
- `isort` - Python import sorter
- `shfmt` - Shell formatter
- `prettier` - HTML/CSS/JSON/YAML/Markdown formatter
- `shellcheck` - Shell linter
- `cppcheck` - C/C++ linter
- `markdownlint` - Markdown linter

### Installation
**Arch:** Already in arch.sh (all from official repos)
**Debian:** Already in debian.sh
- `stylua` → installed via `cargo install stylua` (not in apt)
- `prettier` and `markdownlint` → installed via `npm -g`

### Notes
Format-on-save is enabled by default. To disable temporarily:
- `:FormatDisable` — globally
- `:FormatDisable!` — current buffer only
- `:FormatEnable` — re-enable

---

## Debug.lua (Phase 7)

**Purpose:** Interactive debugger via nvim-dap

Installed only with `--hardware` or `--full`.

### Required
- `gdb` - GNU debugger (C/C++, embedded via gdbserver)
- `lldb` - LLVM debugger (alternative to gdb)

### Installation
**Arch:** Already in arch.sh
**Debian:** Already in debian.sh

---

## Hardware.lua (Phase 9)

**Purpose:** Embedded development for ESP32/ESP8266, AVR (Arduino), and FPGA
(Verilog/VHDL)

Installed only with `--hardware` or `--full`.

### AVR / Arduino

- `arduino-cli` - Arduino sketch build & flash
- `avrdude` - Flash AVR chips (ATtiny, ATmega)
- `avr-gcc` - AVR C compiler
- `avr-libc` - AVR C standard library

### ESP32 / ESP8266

- `esptool` - Flash and manage ESP chips

For full ESP-IDF support, install `esp-idf` separately — see
https://docs.espressif.com/projects/esp-idf/en/latest/

### FPGA / Verilog / VHDL

- `iverilog` - Icarus Verilog simulator
- `verilator` - Verilog simulator / linter
- `yosys` - Open-source synthesis
- `gtkwave` - Waveform viewer
- `verible-verilog-ls` - SystemVerilog LSP

### Installation
**Arch:** Already in arch.sh
- Most from official repos
- `verible-bin` from AUR — requires `paru` or `yay` installed. If neither is
  present, the script skips it and prints a manual-install notice.

**Debian:** Already in debian.sh
- `avrdude`, `gcc-avr`, `avr-libc`, `iverilog`, `verilator`, `yosys`, `gtkwave`
  from apt
- `esptool` → `pip3 install --user esptool`
- `arduino-cli` → official install script to `~/.local/bin`
- `verible-verilog-ls` → prebuilt Linux binary from GitHub releases

**Important:** The Debian path installs several tools to `~/.local/bin`. Make
sure it's in your `$PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Colors (Matugen)

**Purpose:** Color scheme generation from images

### NOTES
Matugen should be setup separately — it is **not** installed by the script
because setup depends on your wallpaper/theme pipeline.

Install from: https://github.com/InioX/matugen

If Matugen isn't present, the config falls back to `gruvbox` automatically
(see `init.lua`).

### Installation
Manual only — not in arch.sh or debian.sh

---

## Manually Managed

These are **not** installed by the script — install separately if you need them:

- **`esp-idf`** — Espressif's full ESP32 SDK, has its own installer
- **Rust / `rustup`** — only if you start doing Rust embedded work
- **`probe-rs`** — Rust-based hardware debugger (`cargo install probe-rs`)
- **Matugen** — see Colors section above

---

## Verification

Every install script ends with a verification section that runs `which <tool>`
for each expected binary and prints:

- ✓ for tools found on `$PATH`
- ✗ for tools missing

Partial installs don't fail the script — review the summary at the end and
re-run if anything shows ✗.
