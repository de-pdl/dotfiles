#!/bin/bash
# ============================================================================
# rice_farm control center — rofi 2.x script-mode backend
#
# Runs under rofi's script mode (rofi-script(5)) and is exec'd from menu.sh:
#   rofi -modi "rc:$SCRIPTS_DIR/control_center.sh" -show rc -theme cc_theme.rasi
# It also works standalone for testing:
#   ROFI_RETV=0 bash control_center.sh                    # top page
#   ROFI_INFO=tab=Color ROFI_RETV=0 bash control_center.sh
#
# Protocol (rofi 2.0.0, doc/rofi-script.5.markdown):
#   - each output line: "<text>\0key\x1fvalue[\x1fkey\x1fvalue...]"
#   - ROFI_RETV: 0 initial call, 1 entry selected (Enter), 2 custom entry
#     (mouse), 3 entry deleted, 10-28 custom keybindings
#   - a selected row's `info` value is handed back in $ROFI_INFO
#   - rows carry "info\x1ftab=<PAGE>[;act=<id>]": tab is the page to
#     (re)render, act is an action to run before re-rendering that page.
#     Selecting a row therefore always ends in re-rendering a page, which is
#     what makes toggles flip live.
#
# Pages: Menu (tabs: Display, Color, Wallpaper, Toggles) plus the sub pages
# Resolution, Harmony, Preset, Wallgallery, Waybar. Status reads are cheap on
# purpose: greps over
# the log tail, one test -f, sourcing rice.conf — matugen never runs on
# render, only as part of an action.
#
# NOTE on stdout: in script mode stdout IS the entry list, so nothing else
# may be written there. log() below uses the common.sh format and destination
# (append to $XDG_STATE_HOME/rice_farm.log) but writes to the file only —
# common.sh's tee-to-stdout would corrupt the list. Actions additionally run
# in a subshell with stdout redirected to stderr, because the real functions
# (gaming_mode_toggle, bg_load.sh, ...) still tee to stdout.
# ============================================================================

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.config/scripts/rice_farm/scripts}"
FUNCTIONS_DIR="${FUNCTIONS_DIR:-$HOME/.config/scripts/rice_farm/functions}"
LOG_FILE="${LOG_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log}"
GAMING_STATE_FILE="${GAMING_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm_gaming}"
RICE_CONF="${RICE_CONF:-$HOME/.config/rice_farm/rice.conf}"

mkdir -p "$(dirname "$LOG_FILE")"

# Existing helpers, sourced exactly like main_rice.sh does. Exec'd from
# show_menu, so this process must source them itself.
for file in "$FUNCTIONS_DIR"/*.sh; do
    [[ -f "$file" ]] && source "$file"
done

# File-only variant of common.sh's log() (same format, same destination).
log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

# ============================================================================
# ROW EMITTERS
# ============================================================================
row()       { printf '%s\n' "$1"; }                                   # plain row
row_info()  { printf '%s\0info\x1f%s\n' "$1" "$2"; }                  # selectable, carries routing info
row_fixed() { printf '%s\0nonselectable\x1ftrue\n' "$1"; }            # nonselectable (status header)

# ============================================================================
# CHEAP STATE READS (never block, never run matugen)
# ============================================================================
read_conf() {
    RICE_AUTO_PRESET=""
    RICE_FORCE_MODE=""
    RICE_HARMONY=""
    [[ -f "$RICE_CONF" ]] && source "$RICE_CONF"
    return 0
}

status_gaming() {
    [[ -f "$GAMING_STATE_FILE" ]] && printf 'ON\n' || printf 'OFF\n'
}

# Latest forced/detected mode from the log tail ("mode=light|dark", written by
# detect_mode / the harmony path / our own toggle below).
status_mode() {
    local m
    m=$(tail -n 500 "$LOG_FILE" 2>/dev/null | grep -aoE 'mode=(light|dark)' | tail -n 1)
    m="${m#mode=}"
    printf '%s\n' "${m:-auto}"
}

# Latest harmony from the log tail. Two line shapes exist:
#   "... Generating colors with matugen (preference: auto, harmony: <h>)..."
#   "... Harmony path: matugen on harmonized swatch (<src> -> <dst>, <h>, mode=..."
status_harmony() {
    local line h=""
    line=$(tail -n 500 "$LOG_FILE" 2>/dev/null \
        | grep -a '🎨' | grep -aE 'Harmony path|Generating colors' | tail -n 1)
    if [[ "$line" == *"Harmony path"* ]]; then
        h=$(sed -n 's/.* -> [^,]*, \([a-zA-Z-]*\), mode=.*/\1/p' <<< "$line")
    else
        h=$(sed -n 's/.*harmony: \([a-zA-Z-]*\)).*/\1/p' <<< "$line")
    fi
    [[ -z "$h" || "$h" == "unset" ]] && h="auto"
    printf '%s\n' "$h"
}

# ============================================================================
# PAGES
# ============================================================================
page_menu() {
    read_conf
    # Harmony slot: a persisted explicit choice (RICE_HARMONY in rice.conf,
    # written by set_harmony) wins; "auto"/absent falls back to the log grep.
    local h
    if [[ -n "${RICE_HARMONY:-}" && "$RICE_HARMONY" != "auto" ]]; then
        h="$RICE_HARMONY"
    else
        h=$(status_harmony)
    fi
    row_fixed "󰄼  preset:${RICE_AUTO_PRESET:-muted} · harmony:$h · mode:$(status_mode) · gaming:$(status_gaming)"
    row_info "󰍹  Display"   "tab=Display"
    row_info "󰏘  Color"     "tab=Color"
    row_info "󰸉  Wallpaper" "tab=Wallpaper"
    row_info "󰌾  Toggles"   "tab=Toggles"
}

page_display() {
    row_info "←  Tabs"                "tab=Menu"
    row_info "Resolution"             "tab=Resolution"
    row_info "Random wallpaper"       "tab=Display;act=random_wp"
    row_info "Pick wallpaper"         "tab=Wallgallery"
    row_info "Reload sway"            "tab=Display;act=reload_sway"
    row_info "Reload monitor positions" "tab=Display;act=reload_mon"
}

page_resolution() {
    row_info "←  Tabs" "tab=Display"
    local json
    json=$(swaymsg -t get_outputs 2>/dev/null) || json=""
    if [[ -z "$json" ]]; then
        row_fixed "swaymsg unavailable"
        return 0
    fi
    # Current mode first and marked; every row routes back here after applying.
    # sway IPC reports refresh in mHz (60000 = 60Hz): /1000 for display, raw
    # integer compare for the current-mode match.
    jq -r '
        .[] | select(.active == true) | .name as $o |
        (.current_mode // {}) as $cm |
        .modes[] |
        (if .width == $cm.width and .height == $cm.height
             and ((.refresh // 0) | floor) == (($cm.refresh // -1) | floor)
         then "0" else "1" end) as $cur |
        "\($cur)\t\($o)|\(.width)x\(.height)@\((.refresh // 0) / 1000)Hz\(if $cur == "0" then " · current" else "" end)"
    ' <<< "$json" | sort | cut -f2- | while IFS= read -r entry; do
        row_info "$entry" "tab=Resolution;act=mode:$entry"
    done
}

page_color() {
    row_info "←  Tabs"             "tab=Menu"
    row_info "Harmony"             "tab=Harmony"
    row_info "Preset"              "tab=Preset"
    row_info "Light / Dark"        "tab=Color;act=toggle_mode"
    row_info "Regenerate colors"   "tab=Color;act=regen"
}

page_harmony() {
    row_info "←  Tabs" "tab=Color"
    local h
    for h in auto none complementary split-complementary triadic analogous; do
        row_info "$h" "tab=Harmony;act=harmony:$h"
    done
}

page_preset() {
    row_info "←  Tabs" "tab=Color"
    local p
    for p in muted vibrant calm; do
        row_info "$p" "tab=Preset;act=preset:$p"
    done
}

page_wallpaper() {
    row_info "←  Tabs"           "tab=Menu"
    row_info "Browse gallery"    "tab=Wallgallery"
    row_info "Random wallpaper"  "tab=Wallpaper;act=random_wp"
}

# Native replacement for the old nested-rofi wallpaper picker: one row per
# image in $WALLPAPER_DIR, the rofi icon trick from functions/wallpaper.sh
# carrying the full path (\x1ficon\x1f<file>) so each row shows a preview.
# Regex must stay identical to wallpaper.sh's find so the gallery lists the
# same files the old picker did.
page_wallgallery() {
    row_info "←  Tabs" "tab=Wallpaper"
    local wp_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
    local sep=$'\x1f' f b listed=0
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        b=$(basename "$f")
        row_info "$b" "tab=Wallgallery;act=wp:${b}${sep}icon${sep}$f"
        listed=1
    done < <(find "$wp_dir" -maxdepth 1 -type f \
                 -iregex '.*\.\(jpg\|jpeg\|png\|avif\|webp\)$' 2>/dev/null | sort)
    [[ "$listed" -eq 1 ]] || row_fixed "No wallpapers found in: $wp_dir"
}

page_toggles() {
    row_info "←  Tabs"                          "tab=Menu"
    row_info "󰖺 Gaming Mode [$(status_gaming)]"  "tab=Toggles;act=gaming"
    row_info "Refresh waybar"                   "tab=Toggles;act=refresh_waybar"
    row_info "󱁻 Waybar theme"                    "tab=Waybar"
}

# Native replacement for waybar_picker.sh's rofi: one row per theme dir under
# ~/.config/waybar/themes/, the active one (config symlink basename) marked
# with ●.
page_waybar() {
    row_info "←  Tabs" "tab=Toggles"
    local themes_dir="$HOME/.config/waybar/themes"
    local cur="" d b target
    if [[ -L "$HOME/.config/waybar/config" ]]; then
        target=$(readlink "$HOME/.config/waybar/config" 2>/dev/null) || target=""
        cur=$(basename "$target" 2>/dev/null) || cur=""
        # waybar_picker.sh links config -> themes/<name>/config (a file), so
        # the target basename is "config"; the theme is its parent dir.
        [[ "$cur" == "config" ]] && cur=$(basename "$(dirname "$target")")
    fi
    local found=0 mark=""
    for d in "$themes_dir"/*/; do
        [[ -d "$d" ]] || continue
        b=$(basename "$d")
        mark=""
        [[ "$b" == "$cur" ]] && mark=" ●"
        row_info "$b$mark" "tab=Waybar;act=wb:$b"
        found=1
    done
    [[ "$found" -eq 1 ]] || row_fixed "No waybar themes found in: $themes_dir"
}

# ============================================================================
# ACTIONS (run in a subshell with stdout -> stderr, see header note)
# ============================================================================
# Persisted harmony (RICE_HARMONY in rice.conf, written by set_harmony below)
# must reach bg_load.sh through the environment: every rofi script-mode
# callback is a fresh process, and bg_load.sh only reads harmony from
# $MATUGEN_HARMONY, never from rice.conf. "auto" means "no explicit harmony"
# (the preset decides), so it exports nothing. RICE_HARMONY is a new conf key
# and harmless to bg_load.sh: it sources rice.conf, picking up an unused
# RICE_HARMONY shell var — verified no such name exists in bg_load.sh today;
# keep it that way when editing that script.
apply_persisted_harmony() {
    [[ -n "${MATUGEN_HARMONY:-}" ]] && return 0   # explicit env already set
    [[ -f "$RICE_CONF" ]] || return 0
    local saved
    saved=$(grep -oP '^RICE_HARMONY="\K[^"]+' "$RICE_CONF" 2>/dev/null || true)
    if [[ -n "$saved" && "$saved" != "auto" ]]; then
        export MATUGEN_HARMONY="$saved"
    fi
}

# Re-run bg_load.sh for the wallpaper currently set (swaylock symlink is
# updated on every bg_load run). Falls back to a random one when unknown.
regenerate_colors() {
    apply_persisted_harmony   # fresh process: re-apply the persisted harmony
    local wp=""
    if [[ -L "$HOME/.config/swaylock/wallpaper.jpg" ]]; then
        wp=$(readlink -f "$HOME/.config/swaylock/wallpaper.jpg" 2>/dev/null || true)
    fi
    if [[ ! -x "$SCRIPTS_DIR/bg_load.sh" ]]; then
        log "⚠️ control-center: bg_load.sh not found at $SCRIPTS_DIR"
        return 0
    fi
    if [[ -z "$wp" || ! -f "$wp" ]]; then
        log "control-center: no current wallpaper known, regenerating via bg_load.sh default"
        "$SCRIPTS_DIR/bg_load.sh" || log "⚠️ bg_load.sh failed"
        return 0
    fi
    log "control-center: regenerating colors for $(basename "$wp")"
    "$SCRIPTS_DIR/bg_load.sh" "$wp" || log "⚠️ bg_load.sh failed"
}

# Wrapper mirroring the existing harmony picker: apply_harmony_choice does the
# env plumbing (MATUGEN_HARMONY / MATUGEN_PREFER, preset persistence for the
# auto paths); we then regenerate for the current wallpaper.
set_harmony() {
    local choice="$1"
    case "$choice" in
        auto|none|complementary|split-complementary|triadic|analogous) ;;
        *) log "⚠️ control-center: unknown harmony '$choice'"; return 0 ;;
    esac
    if declare -F apply_harmony_choice >/dev/null; then
        apply_harmony_choice "$choice"
    else
        log "⚠️ control-center: apply_harmony_choice missing, exporting directly"
        export MATUGEN_PREFER="auto"
        if [[ "$choice" == "auto" ]]; then unset MATUGEN_HARMONY || true; else export MATUGEN_HARMONY="$choice"; fi
    fi
    # Persist the choice so later fresh-process regenerations (mode toggle,
    # regen button) re-apply it; "auto" is stored as-is and means "no explicit
    # harmony" — apply_persisted_harmony ignores it, the preset decides.
    if declare -F save_rice_conf >/dev/null; then
        save_rice_conf "RICE_HARMONY" "$choice"
    else
        log "⚠️ control-center: save_rice_conf missing, harmony not persisted"
    fi
    log "control-center: harmony -> $choice"
    regenerate_colors
}

set_preset() {
    local preset="$1"
    case "$preset" in
        muted|vibrant|calm) ;;
        *) log "⚠️ control-center: unknown preset '$preset'"; return 0 ;;
    esac
    RICE_AUTO_PRESET="$preset"
    export RICE_AUTO_PRESET
    if declare -F save_rice_conf >/dev/null; then
        save_rice_conf "RICE_AUTO_PRESET" "$preset"   # existing persistence point (rice.conf)
    else
        log "⚠️ control-center: save_rice_conf missing, preset not persisted"
    fi
    log "control-center: preset -> $preset"
    regenerate_colors
}

# Light/Dark toggle: flips RICE_FORCE_MODE (persisted to rice.conf like the
# preset), then regenerates. regenerate_colors re-applies any persisted
# RICE_HARMONY first, so an explicit harmony choice survives the toggle. The
# log line carries mode=<new> so the status header's grep reflects the change
# immediately.
toggle_force_mode() {
    read_conf
    local cur="${RICE_FORCE_MODE:-}" new
    if [[ "$cur" == "light" ]]; then
        new="dark"
    elif [[ "$cur" == "dark" ]]; then
        new="light"
    else
        case "$(status_mode)" in light) new="dark" ;; *) new="light" ;; esac
    fi
    export RICE_FORCE_MODE="$new"
    if declare -F save_rice_conf >/dev/null; then
        save_rice_conf "RICE_FORCE_MODE" "$new"
    fi
    log "control-center: mode=$new (forced via RICE_FORCE_MODE)"
    regenerate_colors
}

set_resolution() {
    local spec="$1" out mode
    IFS='|' read -r out mode <<< "$spec"
    if [[ -z "$out" || -z "$mode" ]]; then
        log "⚠️ control-center: bad mode spec '$spec'"
        return 0
    fi
    log "control-center: output $out -> mode $mode"
    if swaymsg output "$out" mode "$mode"; then
        # kanshi owns the monitor positions: a mode flip leaves kanshi's
        # applied profile stale, so the profile's positions no longer match
        # the new mode until kanshi re-asserts them. Every successful mode
        # change is therefore followed by reload_monitors.sh (restarts kanshi
        # + refreshes the background), spawned detached so the rofi menu
        # never blocks on kanshi's sleeps.
        ("$SCRIPTS_DIR/reload_monitors.sh" &) >/dev/null 2>&1
    else
        log "⚠️ control-center: swaymsg mode change failed"
    fi
}

# Apply a gallery choice (act=wp:<basename>): load it via bg_load.sh in the
# caller's stdout-guarded subshell. Replaces change_wallpaper's nested rofi.
apply_wallpaper_choice() {
    local base="$1"
    case "$base" in
        */*) log "⚠️ control-center: rejected wallpaper basename '$base'"; return 0 ;;
    esac
    local wp_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
    local full_path="$wp_dir/$base"
    if [[ ! -f "$full_path" ]]; then
        log "⚠️ control-center: wallpaper not found: $full_path"
        return 0
    fi
    log "🎨 control-center: loading wallpaper: $base"
    "$SCRIPTS_DIR/bg_load.sh" "$full_path" || log "⚠️ bg_load.sh failed"
    notify-send "Wallpaper changed: $base"
}

# Apply a waybar theme choice (act=wb:<name>): mirrors waybar_picker.sh's
# body exactly (symlink config + style.css, pkill -15 -f "waybar$", sleep 1,
# PATH-prefixed relaunch) minus its rofi. Replaces change_waybar.
apply_waybar_choice() {
    local name="$1"
    case "$name" in
        */*) log "⚠️ control-center: rejected waybar theme '$name'"; return 0 ;;
    esac
    local waybar_dir="$HOME/.config/waybar"
    local themes_dir="$waybar_dir/themes"
    if [[ ! -d "$themes_dir/$name" ]]; then
        log "⚠️ control-center: waybar theme not found: $themes_dir/$name"
        return 0
    fi
    log "control-center: switching waybar theme: $name"
    ln -sf "$themes_dir/$name/config" "$waybar_dir/config"
    ln -sf "$themes_dir/$name/style.css" "$waybar_dir/style.css"

    pkill -15 -f "waybar$"
    sleep 1

    # Launch with explicit PATH in environment (as waybar_picker.sh does)
    PATH="$HOME/.local/bin:$PATH" waybar &

    log "✅ control-center: theme: $name"
    notify-send "Rice Farm" "Waybar theme: $name"
}

run_action() {
    local act="$1"
    (
        case "$act" in
            gaming)         log "control-center: gaming mode toggle"; gaming_mode_toggle ;;
            refresh_waybar) refresh_waybar ;;
            random_wp)      random_wallpaper ;;
            reload_sway)    reload_sway ;;
            reload_mon)     "$SCRIPTS_DIR/reload_monitors.sh" ;;
            regen)          regenerate_colors ;;
            toggle_mode)    toggle_force_mode ;;
            preset:*)       set_preset "${act#preset:}" ;;
            harmony:*)      set_harmony "${act#harmony:}" ;;
            mode:*)         set_resolution "${act#mode:}" ;;
            wp:*)           apply_wallpaper_choice "${act#wp:}" ;;
            wb:*)           apply_waybar_choice "${act#wb:}" ;;
            *)              log "control-center: unknown action '$act'" ;;
        esac
    ) >&2   # action output (incl. common.sh log()'s tee) must not reach the list
}

# ============================================================================
# ROUTER
# ============================================================================
main() {
    local sel="${1:-}" retv="${ROFI_RETV:-}" info="${ROFI_INFO:-}"
    local tab="" act="" page="" p
    local -a parts=()

    if [[ -n "$info" ]]; then
        IFS=';' read -ra parts <<< "$info"
        for p in "${parts[@]}"; do
            case "$p" in
                tab=*) tab="${p#tab=}" ;;
                act=*) act="${p#act=}" ;;
            esac
        done
    fi

    if [[ -n "$act" ]]; then
        [[ -z "$tab" ]] && tab="Menu"
        run_action "$act"
        page="$tab"
    elif [[ -n "$tab" ]]; then
        page="$tab"
    elif [[ -z "$retv" || "$retv" == "0" ]]; then
        page="Menu"
    else
        # RETV 1/2/3/10-28 without info (typed text / custom entry): fall back
        # to matching the raw selection, else stay on the top page.
        case "$sel" in
            *Display*)  page="Display" ;;
            *Color*)    page="Color" ;;
            *Wallpaper*) page="Wallpaper" ;;
            *Toggles*)  page="Toggles" ;;
            *)          page="Menu" ;;
        esac
    fi

    case "$page" in
        Display)    page_display ;;
        Color)      page_color ;;
        Wallpaper)  page_wallpaper ;;
        Toggles)    page_toggles ;;
        Harmony)    page_harmony ;;
        Preset)     page_preset ;;
        Wallgallery) page_wallgallery ;;
        Waybar)     page_waybar ;;
        Resolution) page_resolution ;;
        *)          page_menu ;;
    esac
}

main "$@"
