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

# opencode
fish_add_path /home/ayush/.opencode/bin

set -gx LITELLM_KEY "sk-admin-team-stack-2026"
set -gx LLAMA_CACHE /mnt/vm/llama-models
#source ~/.config/fish/conf.d/


