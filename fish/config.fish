# ~/.config/fish/config.fish
# =============================================================================
# FISH SHELL CONFIGURATION - Main Entry Point
# =============================================================================

# Disable default greeting
set fish_greeting

# echo "Welcome to Fish"
if status is-interactive
    fastfetch
end

# Fish automatically sources files in ~/.config/fish/conf.d/
# No need to manually source them here

starship init fish | source

# Per-machine config, not synced
if test -f ~/.config/fish/config.local.fish
    source ~/.config/fish/config.local.fish
end
