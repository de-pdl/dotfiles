# ~/.config/fish/conf.d/20_abbreviations.fish
# =============================================================================
# ABBREVIATIONS (Better than aliases - expand on space/enter)
# =============================================================================

# --- NAVIGATION ---
abbr -a cd. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'
abbr -a mkdir 'mkdir -p'

# --- LIST ---
abbr -a ll 'ls -lah'
abbr -a la 'ls -la'
abbr -a l 'ls -l'

# --- FILE OPERATIONS ---
abbr -a cp 'cp -iv'
abbr -a mv 'mv -iv'
abbr -a rm 'rm -iv'

# --- EDITORS ---
abbr -a v nvim
abbr -a vi nvim
abbr -a vim nvim

# --- GIT ---
abbr -a g git
abbr -a ga 'git add'
abbr -a gaa 'git add .'
abbr -a gc 'git commit'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a gsh 'git show'
abbr -a glog 'git log --oneline --graph'

# --- PACKAGE MANAGERS ---
abbr -a pacman 'pacman --color=auto'
abbr -a yay 'yay --color=auto'
abbr -a paru 'paru --color=auto'

# --- CONFIG SHORTCUTS ---
abbr -a dotfiles 'cd ~/.dotfiles'
abbr -a nvimrc 'nvim ~/.config/nvim/init.lua'
abbr -a fishrc 'nvim ~/.config/fish/config.fish'
abbr -a swayrc 'nvim ~/.config/sway/config'

