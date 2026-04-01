# ~/.config/fish/conf.d/30_functions.fish
# =============================================================================
# CUSTOM FUNCTIONS
# =============================================================================

# --- CD WITH LS ---
function cd
    builtin cd $argv
    and ls -lah
end

# --- CREATE AND ENTER DIRECTORY ---
function mkcd
    if test (count $argv) -eq 0
        echo "Usage: mkcd <directory>"
        return 1
    end
    mkdir -p $argv
    and cd $argv
end

# --- GIT CLONE AND ENTER ---
function gclone
    if test (count $argv) -eq 0
        echo "Usage: gclone <repo>"
        return 1
    end
    
    set repo $argv[1]
    set dir (basename $repo .git)
    git clone $repo
    and cd $dir
end

# --- EXTRACT ARCHIVES ---
function extract
    if test (count $argv) -eq 0
        echo "Usage: extract <file>"
        return 1
    end

    switch $argv[1]
        case '*.tar.bz2'
            tar xjf $argv[1]
        case '*.tar.gz'
            tar xzf $argv[1]
        case '*.bz2'
            bunzip2 $argv[1]
        case '*.rar'
            unrar x $argv[1]
        case '*.gz'
            gunzip $argv[1]
        case '*.tar'
            tar xf $argv[1]
        case '*.tbz2'
            tar xjf $argv[1]
        case '*.tgz'
            tar xzf $argv[1]
        case '*.zip'
            unzip $argv[1]
        case '*.Z'
            uncompress $argv[1]
        case '*.7z'
            7z x $argv[1]
        case '*'
            echo "extract: '$argv[1]' - unknown archive method"
            return 1
    end
end

# --- PRETTY PRINT JSON ---
function prettyjson
    if test (count $argv) -eq 0
        echo "Usage: prettyjson <file>"
        return 1
    end
    python3 -m json.tool $argv[1] | less -R
end

# --- FIND IN FILES ---
function findin
    if test (count $argv) -lt 2
        echo "Usage: findin <pattern> <directory>"
        return 1
    end
    grep -r $argv[1] $argv[2] --include="*.fish" --include="*.lua" --include="*.sh"
end

# --- QUICK BACKUP ---
function backup
    if test (count $argv) -eq 0
        echo "Usage: backup <file>"
        return 1
    end
    cp -v $argv[1] "$argv[1].backup.$(date +%Y%m%d-%H%M%S)"
end

# --- SYSTEM INFO ---
function sysinfo
    echo "=== System Information ==="
    uname -a
    echo ""
    echo "=== Disk Usage ==="
    df -h | head -n 4
    echo ""
    echo "=== Memory Usage ==="
    free -h
end

# --- STARTUP TIME ---
function fish_startup_time
    fish --version
    time fish -i -c 'exit'
end

# --- TERM UI STUFF
function mycat
    /bin/cat $argv | xclip -selection clipboard
    echo "copied to clipboard"
end

function fastfetch
    command fastfetch -c ~/.config/fish/shell_config/neofetch.jsonc $argv
end

