#!/usr/bin/env bash
# bash-it - Bash framework for aliases, completions, and themes

MODULE_DIR="$HOME/.bash_it"
MODULE_REPO="https://github.com/Bash-it/bash-it.git"
MODULE_CORE=true

post_install() {
    # Run bash-it silent install (doesn't modify bashrc - we handle that)
    bash "$MODULE_DIR/install.sh" --silent --no-modify-config
    
    # Configure bash-it components from our config
    local components_file="$SCRIPT_DIR/config/bash-it-components"
    if [[ -f "$components_file" ]]; then
        configure_bash_it_components "$components_file"
    fi
    
    # Install our custom liquidprompt theme fix
    local theme_fix="$SCRIPT_DIR/config/liquidprompt.theme.bash"
    if [[ -f "$theme_fix" ]]; then
        cp "$theme_fix" "$MODULE_DIR/themes/liquidprompt/liquidprompt.theme.bash"
    fi

    install_blesh_fix
}

# Swap bash-it's blesh plugin for our copy, which skips ble-import when ble.sh
# didn't load (it never loads under `bash -c`). The copy lives in enabled/,
# which bash-it's git ignores, so `bash-it update` sees no local change.
install_blesh_fix() {
    local blesh_fix="$SCRIPT_DIR/config/blesh.plugin.bash"
    [[ -f "$blesh_fix" ]] || return 0

    local enabled
    for enabled in "$MODULE_DIR"/enabled/*---blesh.plugin.bash; do
        [[ -e "$enabled" ]] || continue
        # Remove first: cp onto the symlink would overwrite bash-it's own file
        rm -f "$enabled"
        cp "$blesh_fix" "$enabled"
    done
}

configure_bash_it_components() {
    local config_file="$1"
    local current_section=""
    
    # Source bash-it to get the bash-it function
    export BASH_IT="$MODULE_DIR"
    source "$MODULE_DIR/bash_it.sh" 2>/dev/null || true
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check for section headers
        if [[ "$line" =~ ^\[([a-z]+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Enable component using bash-it function
        if [[ -n "$current_section" ]] && [[ -n "$line" ]]; then
            local component="${line// /}"
            bash-it enable "$current_section" "$component" 2>/dev/null || true
        fi
    done < "$config_file"
}

update() {
    export BASH_IT="$MODULE_DIR"
    source "$MODULE_DIR/bash_it.sh" 2>/dev/null || true
    # Before the update: bash-it restarts the shell once it has updated
    install_blesh_fix
    bash-it update stable
}
