#!/usr/bin/env bash
# nano - Nano editor with syntax highlighting

MODULE_DIR="$HOME/.nano"
MODULE_BIN="nano"

is_installed() {
    # Check both nano binary AND syntax highlighting
    command_exists nano && [[ -d "$MODULE_DIR" ]]
}

install() {
    # Install nano if not present
    if ! command_exists nano; then
        log_info "Installing nano..."
        RUN_AS_ROOT_OPERATION="install nano" run_as_root $PKG_INSTALL nano || {
            log_warning "Could not install nano via package manager"
        }
    fi
    
    # Clone syntax highlighting repo
    if [[ ! -d "$MODULE_DIR" ]]; then
        log_info "Installing nano syntax highlighting..."
        git clone --depth=1 https://github.com/galenguyer/nano-syntax-highlighting.git "$MODULE_DIR" || return 1
    fi
    
    return 0
}

post_install() {
    # Create nanorc include if it doesn't exist
    if ! grep -q "include.*\.nano" "$HOME/.nanorc" 2>/dev/null; then
        echo 'include "~/.nano/*.nanorc"' >> "$HOME/.nanorc"
    fi
}

update() {
    (cd "$MODULE_DIR" && git pull)
}
