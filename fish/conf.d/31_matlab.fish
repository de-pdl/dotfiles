# ~/.config/fish/conf.d/31_matlab.fish
# =============================================================================
# MATLAB TMUX SESSION FUNCTIONS
# =============================================================================
# Manages a persistent MATLAB session via host-side tmux. MATLAB itself runs
# inside the distrobox (dispatched by ~/.local/bin/matlab wrapper), but tmux,
# logs, and state live on the host.
# =============================================================================

# --- START / ATTACH ---
function start_matlab --description "Start or attach to the persistent MATLAB tmux session"
    set -l session matlab
    set -l state_dir "$HOME/.local/state/matlab"
    set -l log_file "$state_dir/daemon.log"
    set -l launcher "$HOME/.config/matlab-tools/bin/matlab-daemon-launch"

    mkdir -p $state_dir

    if tmux has-session -t $session 2>/dev/null
        echo "→ attaching to existing matlab session"
        tmux attach -t $session
        return 0
    end

    echo "→ starting new matlab session"
    : > $log_file

    # script wraps the launcher in a pty so MATLAB stays interactive AND the
    # output mirrors to the log file. The launcher handles MATLAB's quoting
    # internally — we only need ONE pair of quotes here.
    set -l logged_cmd "script -qfc $launcher $log_file"

    tmux new-session -d -s $session -n main -x 220 -y 50 $logged_cmd
    tmux split-window -t $session:main.0 -v -p 40 "tail -f $log_file"
    tmux split-window -t $session:main.1 -h -p 50 "$SHELL"
    tmux select-pane -t $session:main.0
    tmux attach -t $session
end

# --- STATUS ---
function matlab_status --description "Check if the MATLAB tmux session is running"
    if tmux has-session -t matlab 2>/dev/null
        set -l pid (tmux list-panes -t matlab:main.0 -F '#{pane_pid}')
        echo "✓ matlab session running (pane 0 pid: $pid)"
        echo ""
        echo "panes:"
        tmux list-panes -t matlab:main -F "  #{pane_index}: #{pane_current_command} (#{pane_width}x#{pane_height})"
        return 0
    else
        echo "✗ matlab session not running"
        return 1
    end
end

# --- STOP ---
function matlab_stop --description "Kill the MATLAB tmux session (sends exit first, then kills)"
    if not tmux has-session -t matlab 2>/dev/null
        echo "no matlab session running"
        return 0
    end

    echo "→ sending 'exit' to MATLAB..."
    tmux send-keys -t matlab:main.0 "exit" Enter

    set -l waited 0
    while tmux has-session -t matlab 2>/dev/null; and test $waited -lt 5
        sleep 1
        set waited (math $waited + 1)
    end

    if tmux has-session -t matlab 2>/dev/null
        echo "→ MATLAB didn't exit, killing session"
        tmux kill-session -t matlab
    else
        echo "✓ stopped cleanly"
    end
end
