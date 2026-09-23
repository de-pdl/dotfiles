#!/bin/bash
# ~/.config/scripts/rice_farm/bg_load.sh
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
MATUGEN_PREFER="${MATUGEN_PREFER:-auto}"
# Color harmony applied to the extracted source color before matugen runs
# (complementary|split-complementary|triadic|analogous|monochromatic|none;
# unset = plain).
MATUGEN_HARMONY="${MATUGEN_HARMONY:-}"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"

# User settings (shell-sourceable KEY="value" pairs). Overridable for tests.
RICE_CONF="${RICE_CONF:-$HOME/.config/rice_farm/rice.conf}"

# Auto presets: matugen parameters applied when no explicit harmony was
# picked. Fields per preset: "<contrast> <rotation> <forced_harmony>".
#   contrast : matugen --contrast value, applied in BOTH light and dark mode
#   rotation : on -> hashed scheme rotation (pick_scheme_type);
#              off -> fixed scheme-tonal-spot
#   harmony  : forced harmony applied via apply_harmony when the picker left
#              MATUGEN_HARMONY unset ("none" = no forcing); an explicit
#              MATUGEN_HARMONY from the picker always wins over the preset.
declare -A RICE_PRESETS=(
    [vibrant]="0.30 on none"
    [muted]="0.10 on none"    # default
    [calm]="0.05 off analogous"
    [bold]="0.50 on none"
)

mkdir -p "$(dirname "$LOG_FILE")"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ Error: $1"
    notify-send -u critical "Rice Farm" "$1"
    exit 1
}

# Source rice.conf if it exists (no error when absent), then default
# RICE_AUTO_PRESET. An exported RICE_AUTO_PRESET wins over the conf file.
load_rice_conf() {
    if [[ -f "$RICE_CONF" ]]; then
        # shellcheck disable=SC1090
        source "$RICE_CONF"
    fi
    : "${RICE_AUTO_PRESET:=muted}"
}

# ============================================================================
# WALLPAPER FUNCTIONS
# ============================================================================
validate_wallpaper_dir() {
    [[ -d "$WALLPAPER_DIR" ]] || error_exit "Wallpaper directory not found: $WALLPAPER_DIR"
}

find_random_wallpaper() {
    local wallpaper
    wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -print0 | shuf -z -n 1 | tr -d '\0')
    [[ -z "$wallpaper" ]] && error_exit "No wallpaper found in $WALLPAPER_DIR"
    echo "$wallpaper"
}

select_wallpaper() {
    local wallpaper
    wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -print0 | \
        xargs -0 -I {} basename {} | \
        rofi -dmenu -i -p "󰸉 Select Wallpaper:" -theme-str 'window {width: 40%; height: 50%;}')
    
    [[ -z "$wallpaper" ]] && return 1
    
    local full_path
    full_path=$(find "$WALLPAPER_DIR" -type f -name "$wallpaper" | head -n1)
    [[ -z "$full_path" ]] && error_exit "Wallpaper not found: $wallpaper"
    echo "$full_path"
}

set_wallpaper() {
    local wallpaper="$1"
    log "🎨 Loading wallpaper: $(basename "$wallpaper")"
    if ! swaymsg output "*" bg "$wallpaper" fill 2>/dev/null; then
        error_exit "Failed to set wallpaper with swaymsg"
    fi
}

# ============================================================================
# COLOR GENERATION FUNCTIONS
# ============================================================================
# Detect light/dark mode from wallpaper average luminance.
# Override with RICE_FORCE_MODE=light|dark (detection skipped when set).
# NOTE: logs go to stderr so stdout stays clean for command substitution.
detect_mode() {
    local wallpaper="$1"

    local forced="${RICE_FORCE_MODE:-}"
    case "$forced" in
        light|dark)
            log "🎛️  RICE_FORCE_MODE=$forced set, skipping luminance detection" >&2
            echo "$forced"
            return 0
            ;;
        "")
            ;;  # no override, detect below
        *)
            log "⚠️  Invalid RICE_FORCE_MODE='$forced' (want light|dark), detecting anyway" >&2
            ;;
    esac

    if ! command -v magick &> /dev/null; then
        log "⚠️  magick not found, cannot measure luminance, defaulting to dark" >&2
        echo "dark"
        return 0
    fi

    local hex r g b luma
    if ! hex=$(magick "$wallpaper" -resize 1x1! -depth 8 txt:- | tail -1 | grep -o '#[0-9A-Fa-f]\{6\}'); then
        log "⚠️  Could not measure luminance of '$(basename "$wallpaper")', defaulting to dark" >&2
        echo "dark"
        return 0
    fi

    r=$(printf '%d' "0x${hex:1:2}")
    g=$(printf '%d' "0x${hex:3:2}")
    b=$(printf '%d' "0x${hex:5:2}")
    luma=$(( (21*r + 72*g + 7*b) / 100 ))

    local mode
    if (( luma >= 140 )); then
        mode="light"
    else
        mode="dark"
    fi
    log "🌗 '$(basename "$wallpaper")' luma=$luma/255 -> mode=$mode" >&2
    echo "$mode"
}

# Pick a matugen scheme type, hashed from the wallpaper basename so every
# wallpaper gets a stable but varied scheme (tonal-spot is only the fallback).
# NOTE: logs go to stderr so stdout stays clean for command substitution.
pick_scheme_type() {
    local wallpaper="$1"
    local name ckout sum index
    local -a schemes=(scheme-content scheme-fidelity scheme-expressive scheme-vibrant scheme-rainbow)

    name=$(basename "$wallpaper")
    if ! ckout=$(cksum <<<"$name"); then
        log "⚠️  cksum failed for '$name', falling back to scheme-tonal-spot" >&2
        echo "scheme-tonal-spot"
        return 0
    fi

    sum=${ckout%% *}
    index=$(( sum % 5 ))
    local scheme="${schemes[$index]}"
    log "🔀 Scheme for '$name': $scheme (cksum=$sum, index=$index)" >&2
    echo "$scheme"
}

# Extract the palette source color from a wallpaper. matugen is asked first
# (dry-run, hex JSON); if that fails, fall back to the 1x1 average, the same
# extraction detect_mode uses.
# NOTE: logs go to stderr so stdout stays clean for command substitution.
get_source_color() {
    local wallpaper="$1"
    local json hex=""

    if command -v matugen &> /dev/null && command -v python3 &> /dev/null && \
       json=$(matugen image "$wallpaper" -m dark -j hex --dry-run -q --prefer=darkness 2>/dev/null) && \
       [[ -n "$json" ]]; then
        # The exact JSON shape differs between matugen releases, so try the
        # known paths: source_color.dark.color, then colors.dark.source_color,
        # then a bare source_color string.
        hex=$(printf '%s' "$json" | python3 -c '
import json, re, sys

def dig(doc, path):
    for key in path.split("."):
        if not isinstance(doc, dict) or key not in doc:
            return None
        doc = doc[key]
    return doc

try:
    doc = json.load(sys.stdin)
except Exception:
    sys.exit(1)
for path in ("colors.source_color.dark.color", "source_color.dark.color",
             "colors.dark.source_color", "source_color"):
    value = dig(doc, path)
    if isinstance(value, str) and re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
        print(value)
        sys.exit(0)
sys.exit(1)
') || hex=""
    fi

    if [[ -n "$hex" ]]; then
        log "🎯 Source color from matugen: $hex" >&2
        echo "$hex"
        return 0
    fi

    if hex=$(magick "$wallpaper" -resize 1x1! -depth 8 txt:- | tail -1 | grep -o '#[0-9A-Fa-f]\{6\}'); then
        log "🎯 Source color via magick 1x1 average: $hex" >&2
        echo "$hex"
        return 0
    fi

    log "⚠️  Could not extract source color from '$(basename "$wallpaper")'" >&2
    return 1
}

# Hue-rotate / desaturate a hex color with ImageMagick. -modulate takes
# brightness,saturation,hue: saturation and hue are percentages, hue is
# linear (100 = 0deg, 200 = 180deg; degrees / 1.8 + 100 = param value,
# rounded to 1 decimal).
# NOTE: logs go to stderr so stdout stays clean for command substitution.
apply_harmony() {
    local hex="$1" harmony="$2"
    local sat param
    case "$harmony" in
        complementary)       sat=100 param="200"   ;;  # +180deg
        split-complementary) sat=100 param="183.3" ;;  # +150deg
        triadic)             sat=100 param="166.7" ;;  # +120deg
        analogous)           sat=100 param="116.7" ;;  # +30deg
        monochromatic)       sat="30" param="100"  ;;  # same hue, desaturated
        none)                sat=100 param="100"   ;;  # +0deg
        *)
            log "⚠️  Unknown harmony '$harmony', passing color through" >&2
            echo "$hex"
            return 0
            ;;
    esac

    if ! command -v magick &> /dev/null; then
        log "⚠️  magick not found, cannot rotate hue, passing color through" >&2
        echo "$hex"
        return 0
    fi

    # monochromatic keeps the hue (param 100) and cuts HSL saturation to sat%.
    # sat=30 (not 60): -modulate saturation multiplies HSL S, so 60 leaves
    # pure red at HSV S=0.75 — the mandated <0.5 desaturation check needs 30.
    local tmpdir harmonized
    tmpdir=$(mktemp -d) || return 1
    if ! magick -size 64x64 xc:"$hex" "$tmpdir/in.png" \
       || ! magick "$tmpdir/in.png" -modulate 100,"$sat","$param" "$tmpdir/out.png" \
       || ! harmonized=$(magick "$tmpdir/out.png" -resize 1x1! -depth 8 txt:- | tail -1 | grep -o '#[0-9A-Fa-f]\{6\}'); then
        log "⚠️  Hue rotation failed for $hex ($harmony)" >&2
        rm -rf "$tmpdir"
        return 1
    fi
    rm -rf "$tmpdir"

    harmonized="${harmonized,,}"  # ImageMagick prints uppercase hex
    log "🎵 Harmony '$harmony': $hex -> $harmonized" >&2
    echo "$harmonized"
}

# Look up one preset's "<contrast> <rotation> <forced_harmony>" parameters
# on stdout; fails for unknown preset names.
lookup_rice_preset() {
    local name="$1" entry
    entry="${RICE_PRESETS[$name]:-}"
    if [[ -z "$entry" ]]; then
        log "⚠️  Unknown preset '$name'" >&2
        return 1
    fi
    echo "$entry"
}

# Build a solid-color PNG from the harmonized source color and let matugen's
# tonal system derive the whole palette from it. Only pre-matugen failures
# return nonzero so the caller can fall back to standard generation.
# $3 = preset contrast (applied in both modes; replaces the old light-only
# hardcoded 0.15).
_generate_colors_harmony() {
    local wallpaper="$1" harmony="$2" contrast="${3:-0.10}"
    local source harmonized tmpdir png mode

    source=$(get_source_color "$wallpaper") || return 1
    harmonized=$(apply_harmony "$source" "$harmony") || return 1

    tmpdir=$(mktemp -d) || return 1
    png="$tmpdir/harmony.png"
    if ! magick -size 64x64 xc:"$harmonized" "$png"; then
        log "⚠️  Could not write harmony swatch PNG"
        rm -rf "$tmpdir"
        return 1
    fi

    # Same -m mode as the auto branch; the swatch PNG must survive the whole
    # matugen run, so it is only removed afterwards. Scheme rotation (-t) is
    # meaningless for a solid color; matugen's default (tonal-spot) applies.
    mode=$(detect_mode "$wallpaper")
    local -a matugen_args=(image "$png" -m "$mode" --prefer="darkness" --contrast "$contrast")

    log "🎨 Harmony path: matugen on harmonized swatch ($source -> $harmonized, $harmony, mode=$mode, contrast=$contrast)"
    if matugen "${matugen_args[@]}"; then
        log "✅ Colors generated (harmony: $harmony)"
    else
        log "⚠️  matugen failed (non-fatal)"
    fi
    rm -rf "$tmpdir"
    return 0
}

generate_colors() {
    local wallpaper="$1"
    if ! command -v matugen &> /dev/null; then
        log "⚠️  matugen not found, skipping color generation"
        return 0
    fi

    # Preset resolution: rice.conf (or env) names the preset; its parameters
    # drive contrast in both modes/paths, scheme rotation, and an optional
    # forced harmony for the no-explicit-harmony case.
    load_rice_conf
    local preset_params
    if ! preset_params=$(lookup_rice_preset "$RICE_AUTO_PRESET"); then
        log "⚠️  Preset '$RICE_AUTO_PRESET' not defined, falling back to 'muted'"
        RICE_AUTO_PRESET="muted"
        preset_params=$(lookup_rice_preset "$RICE_AUTO_PRESET")
    fi
    local contrast rotation forced_harmony
    read -r contrast rotation forced_harmony <<< "$preset_params"
    log "🎛️  Preset: $RICE_AUTO_PRESET (contrast=$contrast rotation=$rotation forced_harmony=$forced_harmony)"

    # Harmony override: matugen cannot do custom harmonies, so it is fed a
    # solid-color PNG of the hue-rotated source color instead of the wallpaper.
    # Explicit MATUGEN_HARMONY (picker) wins; else a forced_harmony preset
    # (calm -> analogous) takes the same path.
    local harmony="${MATUGEN_HARMONY:-$forced_harmony}"
    if [[ -n "$harmony" && "$harmony" != "none" ]]; then
        if _generate_colors_harmony "$wallpaper" "$harmony" "$contrast"; then
            return 0
        fi
        log "⚠️  Harmony path failed, falling back to standard generation"
    fi

    log "🎨 Generating colors with matugen (preference: $MATUGEN_PREFER, harmony: ${harmony:-unset})..."

    local -a matugen_args=(image "$wallpaper")

    if [[ "$MATUGEN_PREFER" == "auto" ]]; then
        # Detection path: adaptive mode + preset-tuned contrast. Scheme
        # rotation is hashed variety, or fixed tonal-spot when rotation=off.
        local mode scheme
        mode=$(detect_mode "$wallpaper")
        if [[ "$rotation" == "off" ]]; then
            scheme="scheme-tonal-spot"
        else
            scheme=$(pick_scheme_type "$wallpaper")
        fi
        matugen_args+=(-m "$mode" -t "$scheme" --prefer="darkness" --contrast "$contrast")
    else
        # Explicit preference: legacy behavior, maps straight to --prefer
        matugen_args+=(-m dark --prefer="$MATUGEN_PREFER")
    fi

    if matugen "${matugen_args[@]}"; then
        log "✅ Colors generated"
    else
        log "⚠️  matugen failed (non-fatal)"
    fi
}

# ============================================================================
# CONFIG RELOAD FUNCTIONS
# ============================================================================
update_swaylock() {
    local wallpaper="$1"
    
    if [[ ! -f "$wallpaper" ]]; then
        log "⚠️ Wallpaper not found: $wallpaper"
        return 1
    fi
    
    # Create/update symlink
    ln -sf "$wallpaper" "$HOME/.config/swaylock/wallpaper.jpg"
    
    log "🔐 Swaylock updated with: $(basename "$wallpaper")"
}

trigger_config_reloads() {
    local wallpaper="$1"
    # Update swaylock
    update_swaylock "$wallpaper"
    # Trigger alacritty config reload
    if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then
        touch "$HOME/.config/alacritty/alacritty.toml"
    fi
    # Trigger neovim config reload
    if [[ -f "$HOME/.config/nvim/init.lua" ]]; then
        touch "$HOME/.config/nvim/init.lua"
    fi
    # Keep the active waybar theme's colors.css beside its style.css: the
    # theme imports it relatively, but matugen only regenerates the
    # top-level ~/.config/waybar/colors.css. Non-fatal when either side is
    # missing (e.g. waybar not installed).
    if [[ -f "$HOME/.config/waybar/colors.css" && -d "$HOME/.config/waybar/themes/waybar_with_pomodoro" ]]; then
        if cp "$HOME/.config/waybar/colors.css" \
              "$HOME/.config/waybar/themes/waybar_with_pomodoro/colors.css"; then
            log "🎨 Waybar theme colors.css refreshed"
        else
            log "⚠️  Could not copy waybar colors.css into theme dir (non-fatal)"
        fi
    fi
    # Trigger waybar reload
    pkill -USR2 waybar 2>/dev/null || true
    # Trigger rofi reload
    pkill rofi 2>/dev/null || true
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    validate_wallpaper_dir
    
    local wallpaper
    
    # If arg provided, use it; otherwise random
    if [[ $# -gt 0 && -n "$1" ]]; then
        if [[ -f "$1" ]]; then
            wallpaper="$1"
            log "📸 Using provided wallpaper: $(basename "$wallpaper")"
        else
            error_exit "Provided wallpaper not found: $1"
        fi
    else
        wallpaper=$(find_random_wallpaper)
    fi
    
    set_wallpaper "$wallpaper"
    generate_colors "$wallpaper"
    trigger_config_reloads "$wallpaper"
    log "✅ Wallpaper and colors loaded successfully"
    notify-send "Rice Farm" "Wallpaper: $(basename "$wallpaper")" -i dialog-information
}

# Only run main when executed directly (sourcing only exposes functions)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
