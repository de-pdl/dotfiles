#!/bin/bash
# ============================================================================
# Tests for the rofi script-mode control center.
#
# Run:   bash scripts/rice_farm/tests/test_control_center.sh
#
# Everything runs inside a mktemp HOME fixture: fake state files, a stub
# functions dir, a fake swaymsg on PATH, a stub colors.rasi. The real rice
# config is never touched. Skips are reported loudly, not silently.
# ============================================================================
set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICE_DIR="$(cd "$TESTS_DIR/.." && pwd)"            # scripts/rice_farm
REPO_ROOT="$(cd "$RICE_DIR/../.." && pwd)"         # repo root (for colors.rasi)
CC="$RICE_DIR/scripts/control_center.sh"
THEME="$RICE_DIR/scripts/cc_theme.rasi"
MENU="$RICE_DIR/scripts/menu.sh"

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT
export HOME="$FIX"
export XDG_STATE_HOME="$FIX/.local/state"
export RICE_CONF="$FIX/.config/rice_farm/rice.conf"
export CC_TEST_MARKER="$FIX/marker"
export CC_BGENV="$FIX/bgenv.txt"                   # MATUGEN_HARMONY seen by bg_load stub
export CC_BGARGS="$FIX/bgargs.txt"                 # wallpaper arg seen by bg_load stub
export WALLPAPER_DIR="$FIX/Pictures/wallpaper"     # gallery + wp: action target
CC_TEST_OUT="$FIX/out.txt"                         # raw stdout (bytes, incl \0)

mkdir -p "$FIX/.config/scripts/rice_farm/functions" \
         "$FIX/.config/scripts/rice_farm/scripts" \
         "$FIX/.config/rice_farm" \
         "$FIX/.config/rofi" \
         "$FIX/bin" \
         "$XDG_STATE_HOME" \
         "$FIX/Pictures/wallpaper"

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS + 1)); echo "  PASS: $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }
skip() { SKIP=$((SKIP + 1)); echo "  SKIP (not verified): $1"; }

# ---- fixture content -------------------------------------------------------

# Stub functions dir: control_center.sh sources "$FUNCTIONS_DIR"/*.sh, so the
# stubs stand in for functions/*.sh. gaming_mode_toggle deliberately writes to
# stdout ("POLLUTION-CHECK...") to prove action output cannot leak into the
# rofi entry list.
cat > "$FIX/.config/scripts/rice_farm/functions/00_stubs.sh" <<'EOF'
gaming_mode_toggle()   { echo "POLLUTION-CHECK action stdout must not reach the list"; echo toggled >> "$CC_TEST_MARKER"; }
change_wallpaper()     { :; }
random_wallpaper()     { :; }
refresh_waybar()       { :; }
change_waybar()        { :; }
reload_sway()          { :; }
apply_harmony_choice() { echo "harmony:$1" >> "$CC_TEST_MARKER"; }
# Mirror the real save_rice_conf (functions/wallpaper.sh): KEY="value" lines
# in rice.conf, marker keeps the call trace for older assertions.
save_rice_conf()       {
    grep -v "^$1=" "$RICE_CONF" > "$RICE_CONF.tmp" 2>/dev/null || true
    echo "$1=\"$2\"" >> "$RICE_CONF.tmp"
    mv "$RICE_CONF.tmp" "$RICE_CONF"
    echo "$1=$2" >> "$CC_TEST_MARKER"
}
EOF

# Stub bg_load.sh where control_center.sh looks for it ($SCRIPTS_DIR default
# under the fixture HOME): records the MATUGEN_HARMONY it was invoked with,
# so persistence-through-fresh-process can be asserted end to end.
cat > "$FIX/.config/scripts/rice_farm/scripts/bg_load.sh" <<'EOF'
#!/bin/bash
printf 'MATUGEN_HARMONY=%s\n' "${MATUGEN_HARMONY-}" >> "$CC_BGENV"
printf '%s\n' "${1-}" >> "$CC_BGARGS"
EOF
chmod +x "$FIX/.config/scripts/rice_farm/scripts/bg_load.sh"

# Stub reload_monitors.sh (the kanshi reassert script): the real one restarts
# kanshi and refreshes the background; the stub only records that it ran, so
# both the background spawn from set_resolution and the manual reload_mon
# action can be asserted via the marker.
cat > "$FIX/.config/scripts/rice_farm/scripts/reload_monitors.sh" <<'EOF'
#!/bin/bash
printf 'reload_monitors ran\n' >> "$CC_TEST_MARKER"
EOF
chmod +x "$FIX/.config/scripts/rice_farm/scripts/reload_monitors.sh"

# Fake pkill/waybar/notify-send: the waybar theme switch (mirrored from
# waybar_picker.sh) runs pkill + relaunch + notify; the stubs record the
# calls so tests can assert them without touching the host session.
cat > "$FIX/bin/pkill" <<EOF
#!/bin/bash
printf 'pkill %s\n' "\$*" >> "$FIX/pkill.txt"
EOF
cat > "$FIX/bin/waybar" <<EOF
#!/bin/bash
printf 'waybar launched (PATH=%s)\n' "\$PATH" >> "$FIX/waybar.txt"
EOF
cat > "$FIX/bin/notify-send" <<EOF
#!/bin/bash
printf '%s\n' "\$*" >> "$FIX/notify.txt"
EOF
chmod +x "$FIX/bin/pkill" "$FIX/bin/waybar" "$FIX/bin/notify-send"

# Wallpaper gallery fixture: two images (b created first so sorting is
# actually exercised), one .txt that must never be listed. ../evil sits
# OUTSIDE the dir: a wp: traversal payload would resolve to it, so if the
# basename guard is ever removed, bg_load stub receives it and tests fail.
: > "$WALLPAPER_DIR/b.jpg"
: > "$WALLPAPER_DIR/a.jpg"
: > "$WALLPAPER_DIR/note.txt"
: > "$FIX/Pictures/evil"

# Waybar themes fixture: two themes, ~/.config/waybar/config symlinked at the
# first, so the page can be pinned to mark exactly the active theme.
mkdir -p "$FIX/.config/waybar/themes/alpha" "$FIX/.config/waybar/themes/beta"
: > "$FIX/.config/waybar/themes/alpha/config"
: > "$FIX/.config/waybar/themes/alpha/style.css"
: > "$FIX/.config/waybar/themes/beta/config"
: > "$FIX/.config/waybar/themes/beta/style.css"
ln -sfn "$FIX/.config/waybar/themes/alpha/config" "$FIX/.config/waybar/config"
ln -sfn "$FIX/.config/waybar/themes/alpha/style.css" "$FIX/.config/waybar/style.css"

# Fake swaymsg: one active output DP-1, current mode 1920x1080@60.
cat > "$FIX/bin/swaymsg" <<'EOF'
#!/bin/bash
cat <<'JSON'
[{"name":"DP-1","active":true,
  "current_mode":{"width":1920,"height":1080,"refresh":60000},
  "modes":[{"width":1920,"height":1080,"refresh":60000},
           {"width":1280,"height":720,"refresh":60000}]}]
JSON
EOF
chmod +x "$FIX/bin/swaymsg"

# State: gaming ON; log whose latest entries say mode=dark and harmony
# complementary; conf carrying preset vibrant.
date -Is > "$XDG_STATE_HOME/rice_farm_gaming"
{
    echo "[2026-01-01 10:00:00] 🎨 Generating colors with matugen (preference: auto, harmony: complementary)..."
    echo "[2026-01-01 10:00:01] 🌗 'wall.jpg' luma=42/255 -> mode=dark"
} > "$XDG_STATE_HOME/rice_farm.log"
echo 'RICE_AUTO_PRESET="vibrant"' > "$RICE_CONF"

# colors.rasi for the theme parse test: copy the real generated one if present,
# else a minimal stub carrying the same variable names.
if [[ -f "$REPO_ROOT/rofi/colors.rasi" ]]; then
    cp "$REPO_ROOT/rofi/colors.rasi" "$FIX/.config/rofi/colors.rasi"
else
    printf '* { bg: #000000; bg-alt: #111111; fg: #ffffff; fg-dim: #888888; accent: #ff0000; accent-fg: #ffffff; accent-subtle: #330000; accent-subtle-fg: #ffffff; urgent: #ff0000; urgent-fg: #ffffff; border-color: #888888; selected-bg: #ff0000; selected-fg: #ffffff; background-color: transparent; text-color: @fg; }\n' \
        > "$FIX/.config/rofi/colors.rasi"
fi

# run_cc <args...>: run the control center under the fixture, capture raw
# stdout to a file (bash command substitution would strip \0 bytes).
run_cc() {
    PATH="$FIX/bin:$PATH" ROFI_RETV="${ROFI_RETV-}" ROFI_INFO="${ROFI_INFO-}" \
        bash "$CC" "$@" > "$CC_TEST_OUT" 2>"$FIX/err.txt"
}

echo "== 1. syntax =="
if bash -n "$CC"; then ok "bash -n control_center.sh"; else bad "bash -n control_center.sh"; fi
if bash -n "$MENU"; then ok "bash -n menu.sh"; else bad "bash -n menu.sh"; fi
if bash -n "$TESTS_DIR/test_control_center.sh"; then ok "bash -n test file"; else bad "bash -n test file"; fi

echo "== 2. top page render (ROFI_RETV=0, no args) =="
run_cc
if grep -aq "Display" "$CC_TEST_OUT"; then ok "tab: Display"; else bad "tab: Display"; fi
if grep -aq "Color" "$CC_TEST_OUT"; then ok "tab: Color"; else bad "tab: Color"; fi
if grep -aq "Wallpaper" "$CC_TEST_OUT"; then ok "tab: Wallpaper"; else bad "tab: Wallpaper"; fi
if grep -aq "Toggles" "$CC_TEST_OUT"; then ok "tab: Toggles"; else bad "tab: Toggles"; fi
if [[ "$(grep -ac 'nonselectable.true' "$CC_TEST_OUT")" -eq 1 ]]; then
    ok "exactly one nonselectable status header"
else
    bad "exactly one nonselectable status header"
fi
if grep -aq "preset:vibrant" "$CC_TEST_OUT"; then ok "status shows preset from conf"; else bad "status shows preset from conf"; fi
if grep -aq "harmony:complementary" "$CC_TEST_OUT"; then ok "status shows harmony from log"; else bad "status shows harmony from log"; fi
if grep -aq "mode:dark" "$CC_TEST_OUT"; then ok "status shows mode from log"; else bad "status shows mode from log"; fi
if grep -aq "gaming:ON" "$CC_TEST_OUT"; then ok "status shows gaming from state file"; else bad "status shows gaming from state file"; fi
if [[ "$(wc -l < "$CC_TEST_OUT")" -eq 5 ]]; then
    ok "top page is exactly status + 4 tab lines"
else
    bad "top page is exactly status + 4 tab lines (got $(wc -l < "$CC_TEST_OUT") lines)"
fi

echo "== 3. navigation =="
ROFI_INFO="tab=Color" ROFI_RETV=0 run_cc
for needle in "Harmony" "Preset" "Light / Dark" "Regenerate colors" "tab=Menu"; do
    if grep -aq "$needle" "$CC_TEST_OUT"; then ok "Color page row: $needle"; else bad "Color page row: $needle"; fi
done
if grep -aq "Display" "$CC_TEST_OUT"; then bad "Color page must not list other tabs"; else ok "Color page must not list other tabs"; fi

ROFI_INFO="tab=Toggles" ROFI_RETV=0 run_cc
if grep -aq "Gaming Mode \[ON\]" "$CC_TEST_OUT"; then
    ok "Toggles page shows Gaming Mode [ON] from fixture state"
else
    bad "Toggles page shows Gaming Mode [ON] from fixture state"
fi
for needle in "Refresh waybar" "Waybar theme"; do
    if grep -aq "$needle" "$CC_TEST_OUT"; then ok "Toggles page row: $needle"; else bad "Toggles page row: $needle"; fi
done

ROFI_INFO="tab=Harmony" ROFI_RETV=0 run_cc
for needle in "auto" "none" "complementary" "split-complementary" "triadic" "analogous"; do
    if grep -aq "^$needle" "$CC_TEST_OUT"; then ok "Harmony row: $needle"; else bad "Harmony row: $needle"; fi
done

ROFI_INFO="tab=Preset" ROFI_RETV=0 run_cc
for needle in "muted" "vibrant" "calm"; do
    if grep -aq "^$needle" "$CC_TEST_OUT"; then ok "Preset row: $needle"; else bad "Preset row: $needle"; fi
done
if grep -aq "^bold" "$CC_TEST_OUT"; then bad "Preset page limited to mockup set (no bold)"; else ok "Preset page limited to mockup set (no bold)"; fi

ROFI_INFO="tab=Resolution" ROFI_RETV=0 run_cc
if grep -aq "DP-1|1920x1080@60Hz · current" "$CC_TEST_OUT"; then
    ok "Resolution page lists current mode first, marked"
else
    bad "Resolution page lists current mode first, marked"
fi
if grep -aq "1280x720@60Hz" "$CC_TEST_OUT"; then ok "Resolution page lists other modes"; else bad "Resolution page lists other modes"; fi

echo "== 4. actions =="
rm -f "$CC_TEST_MARKER"
ROFI_INFO="tab=Toggles;act=gaming" ROFI_RETV=1 run_cc "Gaming Mode [ON]"
if [[ -f "$CC_TEST_MARKER" ]] && grep -q "toggled" "$CC_TEST_MARKER"; then
    ok "selecting Gaming Mode ran gaming_mode_toggle (stub marker written)"
else
    bad "selecting Gaming Mode ran gaming_mode_toggle (stub marker written)"
fi
if grep -aq "Gaming Mode" "$CC_TEST_OUT"; then ok "page re-emitted after action"; else bad "page re-emitted after action"; fi
if grep -aq "POLLUTION-CHECK" "$CC_TEST_OUT"; then
    bad "action stdout leaked into the entry list"
else
    ok "action stdout did not leak into the entry list"
fi
if grep -aq "gaming mode toggle" "$XDG_STATE_HOME/rice_farm.log"; then
    ok "action logged via log() convention to rice_farm.log"
else
    bad "action logged via log() convention to rice_farm.log"
fi

ROFI_INFO="tab=Color;act=harmony:triadic" ROFI_RETV=1 run_cc
if grep -aq "harmony:triadic" "$CC_TEST_MARKER"; then
    ok "harmony action routed through apply_harmony_choice"
else
    bad "harmony action routed through apply_harmony_choice"
fi
if grep -aq "Regenerate colors" "$CC_TEST_OUT"; then ok "Color page re-emitted after harmony action"; else bad "Color page re-emitted after harmony action"; fi

ROFI_INFO="tab=Color;act=preset:muted" ROFI_RETV=1 run_cc
if grep -aq "RICE_AUTO_PRESET=muted" "$CC_TEST_MARKER"; then
    ok "preset action persisted via save_rice_conf"
else
    bad "preset action persisted via save_rice_conf"
fi

echo "== 5. theme parse (rofi -dump-theme) =="
if command -v rofi >/dev/null 2>&1; then
    if rofi -no-config -theme "$THEME" -dump-theme > "$FIX/theme.txt" 2>&1; then
        ok "rofi -no-config -theme cc_theme.rasi -dump-theme exits 0"
    else
        bad "rofi -no-config -theme cc_theme.rasi -dump-theme exits 0"
        sed 's/^/        /' "$FIX/theme.txt"
    fi
    if grep -q "640px" "$FIX/theme.txt"; then ok "dumped theme has 640px window"; else bad "dumped theme has 640px window"; fi
else
    skip "rofi is not installed in this environment — theme parse could NOT be verified"
fi

echo "== 6. menu.sh wiring =="
if grep -qF 'exec rofi -show-icons -modi "rc:$SCRIPTS_DIR/control_center.sh"' "$MENU"; then
    ok "show_menu launches rofi in script mode with control_center backend"
else
    bad "show_menu launches rofi in script mode with control_center backend"
fi
if grep -qF 'handle_choice() { :; }' "$MENU"; then
    ok "handle_choice is a no-op"
else
    bad "handle_choice is a no-op"
fi

echo "== 7. harmony persistence (fresh-process regenerations) =="
: > "$CC_BGENV"
printf 'RICE_AUTO_PRESET="vibrant"\n' > "$RICE_CONF"   # clean conf, no RICE_HARMONY

# 7a. Action path: picking a harmony persists it to rice.conf ...
ROFI_INFO="tab=Harmony;act=harmony:analogous" ROFI_RETV=1 run_cc
if grep -q '^RICE_HARMONY="analogous"' "$RICE_CONF"; then
    ok "harmony action persisted RICE_HARMONY=\"analogous\" to rice.conf"
else
    bad "harmony action persisted RICE_HARMONY=\"analogous\" to rice.conf"
fi
# ... and the same fresh process regenerated with it in the env.
if grep -q '^MATUGEN_HARMONY=analogous$' "$CC_BGENV"; then
    ok "action's regeneration saw MATUGEN_HARMONY=analogous"
else
    bad "action's regeneration saw MATUGEN_HARMONY=analogous (got: $(tr '\n' ' ' < "$CC_BGENV"))"
fi

# 7b. Simulated later fresh process (regen button): persisted conf value must
# reach bg_load.sh via the environment even with no MATUGEN_HARMONY in env.
: > "$CC_BGENV"
ROFI_INFO="tab=Color;act=regen" ROFI_RETV=1 run_cc
if grep -q '^MATUGEN_HARMONY=analogous$' "$CC_BGENV"; then
    ok "fresh-process regen re-applied persisted harmony"
else
    bad "fresh-process regen re-applied persisted harmony (got: $(tr '\n' ' ' < "$CC_BGENV"))"
fi

# 7c. Boundary: an explicit MATUGEN_HARMONY in the env wins; the helper is
# called directly in a fresh bash to pin that it never overwrites it.
cat > "$FIX/helper_probe.sh" <<'PROBE'
source "$CC" >/dev/null 2>&1
apply_persisted_harmony
printf 'MATUGEN_HARMONY=%s\n' "${MATUGEN_HARMONY-}"
PROBE
if grep -q '^MATUGEN_HARMONY=triadic$' <(CC="$CC" MATUGEN_HARMONY=triadic bash "$FIX/helper_probe.sh"); then
    ok "helper leaves an already-set MATUGEN_HARMONY alone"
else
    bad "helper leaves an already-set MATUGEN_HARMONY alone"
fi

# 7d. Status header prefers the persisted value over the log grep ...
ROFI_INFO="tab=Menu" ROFI_RETV=0 run_cc
if grep -aq 'harmony:analogous' "$CC_TEST_OUT"; then
    ok "status header shows persisted harmony (log says complementary)"
else
    bad "status header shows persisted harmony (log says complementary)"
fi

# 7e. ... but auto means "no explicit harmony": nothing exported, header
# falls back to the log grep.
sed -i 's/^RICE_HARMONY=.*/RICE_HARMONY="auto"/' "$RICE_CONF"
: > "$CC_BGENV"
ROFI_INFO="tab=Color;act=regen" ROFI_RETV=1 run_cc
if grep -q '^MATUGEN_HARMONY=$' "$CC_BGENV"; then
    ok "RICE_HARMONY=auto exports no MATUGEN_HARMONY"
else
    bad "RICE_HARMONY=auto exports no MATUGEN_HARMONY (got: $(tr '\n' ' ' < "$CC_BGENV"))"
fi
ROFI_INFO="tab=Menu" ROFI_RETV=0 run_cc
if grep -aq 'harmony:complementary' "$CC_TEST_OUT"; then
    ok "RICE_HARMONY=auto: header falls back to log grep"
else
    bad "RICE_HARMONY=auto: header falls back to log grep"
fi

echo "== 8. wallgallery page (native sub-page, no nested rofi) =="
ROFI_INFO="tab=Wallgallery" ROFI_RETV=0 run_cc
if grep -aq "act=wp:a.jpg" "$CC_TEST_OUT" && grep -aq $'icon\x1f'"$WALLPAPER_DIR/a.jpg" "$CC_TEST_OUT"; then
    ok "gallery lists a.jpg with act + full-path icon info"
else
    bad "gallery lists a.jpg with act + full-path icon info"
fi
if grep -aq "act=wp:b.jpg" "$CC_TEST_OUT" && grep -aq $'icon\x1f'"$WALLPAPER_DIR/b.jpg" "$CC_TEST_OUT"; then
    ok "gallery lists b.jpg with act + full-path icon info"
else
    bad "gallery lists b.jpg with act + full-path icon info"
fi
if grep -aq "note.txt" "$CC_TEST_OUT"; then
    bad "gallery excludes non-image files (note.txt leaked in)"
else
    ok "gallery excludes non-image files (note.txt absent)"
fi
la=$(grep -anm1 'act=wp:a.jpg' "$CC_TEST_OUT" | cut -d: -f1)
lb=$(grep -anm1 'act=wp:b.jpg' "$CC_TEST_OUT" | cut -d: -f1)
if [[ -n "$la" && -n "$lb" && "$la" -lt "$lb" ]]; then
    ok "gallery rows sorted (a.jpg before b.jpg)"
else
    bad "gallery rows sorted (a.jpg before b.jpg; got a=$la b=$lb)"
fi
if grep -aq "tab=Wallpaper" "$CC_TEST_OUT"; then
    ok "gallery back-row returns to Wallpaper tab"
else
    bad "gallery back-row returns to Wallpaper tab"
fi

ROFI_INFO="tab=Wallpaper" ROFI_RETV=0 run_cc
if grep -aq "tab=Wallgallery" "$CC_TEST_OUT"; then
    ok "Wallpaper page 'Browse gallery' targets tab=Wallgallery"
else
    bad "Wallpaper page 'Browse gallery' targets tab=Wallgallery"
fi

mkdir -p "$FIX/empty_wp"
WALLPAPER_DIR="$FIX/empty_wp" ROFI_INFO="tab=Wallgallery" ROFI_RETV=0 run_cc
if grep -aq $'nonselectable\x1ftrue' "$CC_TEST_OUT" && ! grep -aq 'act=wp:' "$CC_TEST_OUT"; then
    ok "empty gallery emits a nonselectable notice and no wp: rows"
else
    bad "empty gallery emits a nonselectable notice and no wp: rows"
fi

echo "== 9. waybar page (native sub-page, no nested rofi) =="
ROFI_INFO="tab=Waybar" ROFI_RETV=0 run_cc
for t in alpha beta; do
    if grep -aq "act=wb:$t" "$CC_TEST_OUT"; then ok "waybar page lists theme $t"; else bad "waybar page lists theme $t"; fi
done
if grep -aq '^alpha ●' "$CC_TEST_OUT"; then
    ok "waybar page marks the symlinked theme (alpha ●)"
else
    bad "waybar page marks the symlinked theme (alpha ●)"
fi
if grep -aq '^beta ●' "$CC_TEST_OUT"; then
    bad "waybar page must not mark inactive themes (beta ● leaked in)"
else
    ok "waybar page does not mark inactive themes"
fi
if grep -aq "tab=Toggles" "$CC_TEST_OUT"; then
    ok "waybar page back-row returns to Toggles"
else
    bad "waybar page back-row returns to Toggles"
fi

ROFI_INFO="tab=Toggles" ROFI_RETV=0 run_cc
if grep -aq "tab=Waybar" "$CC_TEST_OUT"; then
    ok "Toggles page 'Waybar theme' row targets tab=Waybar"
else
    bad "Toggles page 'Waybar theme' row targets tab=Waybar"
fi
if grep -aq 'act=change_waybar' "$CC_TEST_OUT"; then
    bad "Toggles page no longer carries act=change_waybar"
else
    ok "Toggles page no longer carries act=change_waybar"
fi

echo "== 10. wallpaper action (wp:) =="
: > "$CC_BGARGS"; rm -f "$FIX/notify.txt"
ROFI_INFO="tab=Wallgallery;act=wp:a.jpg" ROFI_RETV=1 run_cc
if grep -qx "$WALLPAPER_DIR/a.jpg" "$CC_BGARGS"; then
    ok "wp: action ran bg_load.sh with the full wallpaper path"
else
    bad "wp: action ran bg_load.sh with the full wallpaper path (got: $(tr '\n' ' ' < "$CC_BGARGS"))"
fi
if grep -qF 'Wallpaper changed: a.jpg' "$FIX/notify.txt" 2>/dev/null; then
    ok "wp: action sent notify-send 'Wallpaper changed: a.jpg'"
else
    bad "wp: action sent notify-send 'Wallpaper changed: a.jpg'"
fi
if grep -aq 'act=wp:a.jpg' "$CC_TEST_OUT"; then
    ok "gallery page re-emitted after wp: action"
else
    bad "gallery page re-emitted after wp: action"
fi

: > "$CC_BGARGS"; rm -f "$FIX/notify.txt"
ROFI_INFO="tab=Wallgallery;act=wp:../evil" ROFI_RETV=1 run_cc
if grep -q . "$CC_BGARGS"; then
    bad "wp: traversal payload rejected before bg_load (stub got: $(tr '\n' ' ' < "$CC_BGARGS"))"
else
    ok "wp: traversal payload rejected before bg_load ($FIX/Pictures/evil exists and was not read)"
fi
if grep -aq 'rejected wallpaper basename' "$XDG_STATE_HOME/rice_farm.log"; then
    ok "wp: traversal attempt logged as rejected"
else
    bad "wp: traversal attempt logged as rejected"
fi
if grep -qF 'Wallpaper changed' "$FIX/notify.txt" 2>/dev/null; then
    bad "wp: traversal sent no success notification"
else
    ok "wp: traversal sent no success notification"
fi

ROFI_INFO="tab=Display" ROFI_RETV=0 run_cc
if grep -aq 'Pick wallpaper' "$CC_TEST_OUT" && ! grep -aq 'act=pick_wp' "$CC_TEST_OUT"; then
    ok "Display 'Pick wallpaper' row no longer routes through the nested picker"
else
    bad "Display 'Pick wallpaper' row no longer routes through the nested picker"
fi

echo "== 11. waybar theme action (wb:) =="
# Re-point at alpha so the swap to beta is observable.
ln -sfn "$FIX/.config/waybar/themes/alpha/config" "$FIX/.config/waybar/config"
ln -sfn "$FIX/.config/waybar/themes/alpha/style.css" "$FIX/.config/waybar/style.css"
rm -f "$FIX/pkill.txt" "$FIX/waybar.txt" "$FIX/notify.txt"
ROFI_INFO="tab=Toggles;act=wb:beta" ROFI_RETV=1 run_cc
if [[ "$(readlink "$FIX/.config/waybar/config")" == "$FIX/.config/waybar/themes/beta/config" ]]; then
    ok "wb: action re-pointed config symlink at themes/beta/config"
else
    bad "wb: action re-pointed config symlink (got: $(readlink "$FIX/.config/waybar/config"))"
fi
if [[ "$(readlink "$FIX/.config/waybar/style.css")" == "$FIX/.config/waybar/themes/beta/style.css" ]]; then
    ok "wb: action re-pointed style.css symlink at themes/beta/style.css"
else
    bad "wb: action re-pointed style.css symlink (got: $(readlink "$FIX/.config/waybar/style.css"))"
fi
if grep -qF 'pkill -15 -f waybar$' "$FIX/pkill.txt" 2>/dev/null; then
    ok "wb: action stopped waybar with picker's pkill pattern"
else
    bad "wb: action stopped waybar with picker's pkill pattern"
fi
if grep -qF "PATH=$FIX/.local/bin:" "$FIX/waybar.txt" 2>/dev/null; then
    ok "wb: action relaunched waybar with .local/bin PATH prefix"
else
    bad "wb: action relaunched waybar with .local/bin PATH prefix"
fi
if grep -qF 'Waybar theme: beta' "$FIX/notify.txt" 2>/dev/null; then
    ok "wb: action notified 'Waybar theme: beta'"
else
    bad "wb: action notified 'Waybar theme: beta'"
fi

# Traversal: ../../evil must be rejected with symlinks and waybar untouched.
rm -f "$FIX/pkill.txt"
ROFI_INFO="tab=Toggles;act=wb:../../evil" ROFI_RETV=1 run_cc
if [[ "$(readlink "$FIX/.config/waybar/config")" == "$FIX/.config/waybar/themes/beta/config" ]]; then
    ok "wb: traversal left config symlink untouched"
else
    bad "wb: traversal left config symlink untouched"
fi
if [[ -f "$FIX/pkill.txt" ]]; then
    bad "wb: traversal never reached pkill"
else
    ok "wb: traversal never reached pkill"
fi
if grep -aq 'rejected waybar theme' "$XDG_STATE_HOME/rice_farm.log"; then
    ok "wb: traversal attempt logged as rejected"
else
    bad "wb: traversal attempt logged as rejected"
fi

echo "== 12. monitor position reload (kanshi reassert after mode change) =="

# 12a. A mode flip must be followed by a kanshi reassert: set_resolution
# spawns the reload_monitors.sh stub detached, so poll for its marker with a
# bounded wait instead of asserting synchronously (background spawn).
rm -f "$CC_TEST_MARKER"
ROFI_INFO="tab=Resolution;act=mode:DP-1|1280x720@60Hz" ROFI_RETV=1 run_cc
saw_reload=""
for _ in {1..40}; do
    if [[ -f "$CC_TEST_MARKER" ]] && grep -q "reload_monitors ran" "$CC_TEST_MARKER"; then
        saw_reload=1
        break
    fi
    sleep 0.05
done
if [[ -n "$saw_reload" ]]; then
    ok "set_resolution re-asserted kanshi via background reload_monitors.sh"
else
    bad "set_resolution re-asserted kanshi via background reload_monitors.sh"
fi
if grep -aq "1280x720@60Hz" "$CC_TEST_OUT"; then
    ok "Resolution page re-emitted after mode action"
else
    bad "Resolution page re-emitted after mode action"
fi

# 12b. Manual fix button: Display page carries the row routed to reload_mon.
ROFI_INFO="tab=Display" ROFI_RETV=0 run_cc
if grep -aq "Reload monitor positions" "$CC_TEST_OUT" \
   && grep -aq "tab=Display;act=reload_mon" "$CC_TEST_OUT"; then
    ok "Display page lists 'Reload monitor positions' wired to act=reload_mon"
else
    bad "Display page lists 'Reload monitor positions' wired to act=reload_mon"
fi

# 12c. The manual action runs the same script synchronously inside the
# stdout-guarded subshell, so the marker is there without any wait.
rm -f "$CC_TEST_MARKER"
ROFI_INFO="tab=Display;act=reload_mon" ROFI_RETV=1 run_cc
if [[ -f "$CC_TEST_MARKER" ]] && grep -q "reload_monitors ran" "$CC_TEST_MARKER"; then
    ok "reload_mon action executed reload_monitors.sh"
else
    bad "reload_mon action executed reload_monitors.sh"
fi
if grep -aq "Reload monitor positions" "$CC_TEST_OUT"; then
    ok "Display page re-emitted after reload_mon action"
else
    bad "Display page re-emitted after reload_mon action"
fi

echo
echo "RESULT: $PASS passed, $FAIL failed, $SKIP skipped"
[[ "$FAIL" -eq 0 ]]

