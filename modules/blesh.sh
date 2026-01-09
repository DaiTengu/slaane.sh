#!/usr/bin/env bash
# blesh - Bash Line Editor with syntax highlighting and auto-suggestions

MODULE_DIR="$HOME/.local/share/blesh"
MODULE_CORE=true

# Source directory for building
BLESH_SRC="$HOME/.local/src/blesh"
BLESH_REPO="https://github.com/akinomyoga/ble.sh.git"

is_installed() {
    [[ -f "$MODULE_DIR/ble.sh" ]]
}

install() {
    # Clone source
    mkdir -p "$(dirname "$BLESH_SRC")"
    git clone --recursive --depth=1 "$BLESH_REPO" "$BLESH_SRC" || return 1
    
    # Build and install
    (cd "$BLESH_SRC" && make install PREFIX="$HOME/.local") || return 1
    
    # Install blerc config if not present
    if [[ -f "$SCRIPT_DIR/config/blerc" ]] && [[ ! -f "$HOME/.blerc" ]]; then
        cp "$SCRIPT_DIR/config/blerc" "$HOME/.blerc"
    fi
}

update() {
    [[ -d "$BLESH_SRC" ]] || { log_error "Source not found"; return 1; }
    (cd "$BLESH_SRC" && git pull && make install PREFIX="$HOME/.local")
}

uninstall() {
    rm -rf "$MODULE_DIR" "$BLESH_SRC" "$HOME/.local/share/doc/blesh"
}
