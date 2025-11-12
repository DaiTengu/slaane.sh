#!/usr/bin/env bash
# Installation State Tracking

# Ensure SCRIPT_DIR is set
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source common if needed
if ! declare -f log_info &>/dev/null; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

STATE_FILE="$HOME/.slaane.sh/installed-modules"
STATE_DIR="$HOME/.slaane.sh"

# Initialize state directory
init_state_tracking() {
    if [[ ! -d "$STATE_DIR" ]]; then
        mkdir -p "$STATE_DIR"
    fi
    
    if [[ ! -f "$STATE_FILE" ]]; then
        touch "$STATE_FILE"
    fi
}

# Track installed module
track_module_installed() {
    local module_name="$1"
    
    init_state_tracking
    
    # Check if already tracked
    if grep -q "^${module_name}$" "$STATE_FILE" 2>/dev/null; then
        return 0  # Already tracked
    fi
    
    # Add to tracking file
    echo "$module_name" >> "$STATE_FILE"
    log_info "Tracked module: $module_name"
}

# Remove module from tracking
untrack_module() {
    local module_name="$1"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        return 0  # Nothing to untrack
    fi
    
    # Remove from file (if exists)
    if grep -q "^${module_name}$" "$STATE_FILE" 2>/dev/null; then
        # Use sed to remove line (portable)
        local temp_file=$(mktemp)
        grep -v "^${module_name}$" "$STATE_FILE" > "$temp_file"
        mv "$temp_file" "$STATE_FILE"
        log_info "Untracked module: $module_name"
    fi
}

# Get list of installed modules
get_installed_modules() {
    if [[ ! -f "$STATE_FILE" ]]; then
        return 0  # No modules installed
    fi
    
    # Read installed modules (one per line)
    local modules=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && modules+=("$line")
    done < "$STATE_FILE"
    
    echo "${modules[@]}"
}

# Check if module is installed (tracked)
is_module_installed() {
    local module_name="$1"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1  # Not installed
    fi
    
    if grep -q "^${module_name}$" "$STATE_FILE" 2>/dev/null; then
        return 0  # Installed
    else
        return 1  # Not installed
    fi
}

# Clear all tracking (for uninstall all)
clear_tracking() {
    if [[ -f "$STATE_FILE" ]]; then
        > "$STATE_FILE"  # Clear file
    fi
}

