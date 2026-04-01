#!/bin/bash
set -euo pipefail

SCRIPTS_DIR="$HOME/.config/scripts/rice_farm/scripts"
FUNCTIONS_DIR="$HOME/.config/scripts/rice_farm/functions"

LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Load all function definitions
for file in "$FUNCTIONS_DIR"/*.sh ; do
    [[ -f "$file" ]] && source "$file"
done

source "$SCRIPTS_DIR/menu.sh"

# ============================================================================
# ENTRY POINT (this is what actually RUNS)
# ============================================================================
main() {
    check_dependencies           # ← Executes check_dependencies
    local choice
    choice=$(show_menu)          # ← Executes show_menu
    [[ -z "$choice" ]] && exit 0
    handle_choice "$choice"      # ← Executes handle_choice
}

main "$@"                        # ← Executes main function
