#!/bin/bash
# Wallpaper management functions

# Harmony picker (single stage): one harmony choice is enough — a single
# harmonized accent drives the whole palette via matugen's tonal ramps.
# "auto" keeps MATUGEN_HARMONY unset and lets bg_load.sh's preset system
# decide contrast/rotation; "auto-settings" (re)picks and saves that
# preset; "none" and the five harmonies are exported for bg_load.sh.
choose_matugen_preference() {
    local options="auto\nauto-settings\ncomplementary\nsplit-complementary\ntriadic\nanalogous\nmonochromatic\nnone"
    echo -e "$options" | rofi -dmenu -i -p "󰨇 Color Harmony:" -theme-str 'window {width: 20%;}'
}

# --------------------------------------------------------------------------
# save_rice_conf <key> <value>
# Updates a single KEY="value" setting in rice.conf, creating the file
# (documented WALLPAPER_DIR default included) when needed. Same pattern as
# save_layout_config in layouts.sh.
# --------------------------------------------------------------------------
save_rice_conf() {
    local key="$1" value="$2"
    local conf="${RICE_CONF:-$HOME/.config/rice_farm/rice.conf}"
    mkdir -p "$(dirname "$conf")"
    if [[ ! -f "$conf" ]]; then
        printf '# rice_farm settings, sourced by scripts/bg_load.sh\n#WALLPAPER_DIR="$HOME/Pictures/wallpaper"\n' > "$conf"
    fi
    # Remove any existing line for this key, then append the new one.
    # Using a temp file because sed -i behavior varies across systems.
    grep -v "^${key}=" "$conf" > "${conf}.tmp" || true
    echo "${key}=\"${value}\"" >> "${conf}.tmp"
    mv "${conf}.tmp" "$conf"
    log "set $key=$value"
}

# rofi menu with the four auto presets (vibrant/muted/calm/bold).
choose_auto_preset() {
    printf 'vibrant\nmuted\ncalm\nbold\n' | \
        rofi -dmenu -i -p "󰨇 Auto preset:" -theme-str 'window {width: 20%;}'
}

# --------------------------------------------------------------------------
# set_auto_preset : always ask for a preset and persist it to rice.conf.
# --------------------------------------------------------------------------
set_auto_preset() {
    local preset
    preset=$(choose_auto_preset)
    [[ -z "$preset" ]] && return 0
    case "$preset" in
        vibrant|muted|calm|bold)
            save_rice_conf "RICE_AUTO_PRESET" "$preset"
            ;;
        *)
            log "⚠️  Unknown preset '$preset', not saved"
            ;;
    esac
}

# --------------------------------------------------------------------------
# ensure_auto_preset : silent when rice.conf already carries a preset;
# otherwise ask once (second-stage menu) and save the choice.
# --------------------------------------------------------------------------
ensure_auto_preset() {
    local conf="${RICE_CONF:-$HOME/.config/rice_farm/rice.conf}"
    if [[ -f "$conf" ]] && grep -q '^RICE_AUTO_PRESET=' "$conf"; then
        return 0
    fi
    set_auto_preset
}

# --------------------------------------------------------------------------
# apply_harmony_choice <choice>
# Maps one picker choice onto the bg_load.sh environment: preset plumbing
# for the auto entries, MATUGEN_HARMONY export for explicit harmonies.
# --------------------------------------------------------------------------
apply_harmony_choice() {
    local choice="$1"
    [[ -z "$choice" ]] && return 0

    if [[ "$choice" == "auto-settings" ]]; then
        set_auto_preset          # always (re)pick + save
        choice="auto"
    fi
    if [[ "$choice" == "auto" ]]; then
        ensure_auto_preset       # silent when conf already has one
    fi

    # Pass harmony through the environment like MATUGEN_PREFER; "auto" ->
    # MATUGEN_HARMONY unset so bg_load.sh's preset/detection path fires.
    export MATUGEN_PREFER="auto"
    if [[ "$choice" == "auto" ]]; then
        unset MATUGEN_HARMONY || true
    else
        export MATUGEN_HARMONY="$choice"
    fi
}

change_wallpaper() {
    log "Opening wallpaper picker..."

    local harmony
    harmony=$(choose_matugen_preference)
    [[ -z "$harmony" ]] && return 0

    validate_script "$SCRIPTS_DIR/bg_load.sh"
    apply_harmony_choice "$harmony"

    local wallpaper_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
    [[ ! -d "$wallpaper_dir" ]] && error_exit "Wallpaper directory not found: $wallpaper_dir"

    local icon_list=""
    while IFS= read -r filepath; do
        icon_list+="$(basename "$filepath")\0icon\x1f${filepath}\n"
    done < <(
        find "$wallpaper_dir" -maxdepth 1 -type f \
            -iregex '.*\.\(jpg\|jpeg\|png\|avif\|webp\)$' | sort
    )

    [[ -z "$icon_list" ]] && error_exit "No wallpapers found in: $wallpaper_dir"

    local selected
    selected=$(printf '%b' "$icon_list" | \
        rofi -dmenu -i \
             -show-icons \
             -theme ~/.config/rofi/gallery.rasi)

    [[ -z "$selected" ]] && return 0

    local full_path="$wallpaper_dir/$selected"
    [[ ! -f "$full_path" ]] && error_exit "Wallpaper not found: $full_path"

    log "🎨 Loading wallpaper: $selected"
    "$SCRIPTS_DIR/bg_load.sh" "$full_path"
    notify_success "Wallpaper changed: $selected"
}

random_wallpaper() {
    log "Loading random wallpaper..."
    local harmony
    harmony=$(choose_matugen_preference)
    [[ -z "$harmony" ]] && return 0

    validate_script "$SCRIPTS_DIR/bg_load.sh"
    apply_harmony_choice "$harmony"
    "$SCRIPTS_DIR/bg_load.sh"
    notify_success "Random wallpaper loaded"
}
