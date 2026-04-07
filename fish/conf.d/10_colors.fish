# ~/.config/fish/conf.d/10_colors.fish.template
# =============================================================================
# COLOR CONFIGURATION - Matugen generated
# =============================================================================

# Primary palette
set -l primary #bbc3ff
set -l secondary #c3c5dd
set -l tertiary #e6bad7
set -l error #ffb4ab
set -l background #121318
set -l surface #121318
set -l outline #90909a

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
