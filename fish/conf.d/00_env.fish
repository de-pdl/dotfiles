# ~/.config/fish/conf.d/00_env.fish
# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# --- EDITORS ---
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less

# --- TERMINALS & BROWSERS ---
set -gx TERMINAL alacritty
set -gx BROWSER firefox

# --- XDG Base Directory ---
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_CACHE_HOME ~/.cache
set -gx XDG_STATE_HOME ~/.local/state

# --- PATHS ---
set -gx PATH ~/.local/bin $PATH
set -gx PATH ~/.cargo/bin $PATH
set -gx PATH ~/.local/share/nvim/mason/bin $PATH

# --- DOTFILES ---
set -gx DOTFILES ~/.dotfiles

# --- HISTORY ---
set -gx fish_history max
set -gx HISTSIZE 10000
set -gx SAVEHIST 10000

# --- LANGUAGE ---
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
