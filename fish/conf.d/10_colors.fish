# ~/.config/fish/conf.d/10_colors.fish.template
# =============================================================================
# COLOR CONFIGURATION - Matugen generated
# =============================================================================

# Primary palette
set -l primary #cdbdff
set -l secondary #cbc3dc
set -l tertiary #eeb8c9
set -l error #ffb4ab
set -l background #141318
set -l surface #141318
set -l outline #938f99

# --- FISH COLORS ---
set -gx fish_color_command $primary
set -gx fish_color_param $secondary
set -gx fish_color_option $tertiary
set -gx fish_color_error $error
set -gx fish_color_quote $secondary
set -gx fish_color_redirection $tertiary
set -gx fish_color_operator $primary
set -gx fish_color_search_match --background=$secondary
set -gx fish_color_selection --background=$secondary
set -gx fish_color_comment '$outline'
set -gx fish_color_history_current --bold

# --- PROMPT COLORS ---
set -gx fish_color_user $primary
set -gx fish_color_host $secondary
set -gx fish_color_cwd $tertiary
