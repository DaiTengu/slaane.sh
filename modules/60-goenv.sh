#!/usr/bin/env bash
# Module: goenv installation
# Installs goenv (Go version manager)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

GOENV_REPO="https://github.com/go-nv/goenv.git"
GOENV_DIR="${GOENV_ROOT:-$HOME/.goenv}"

check_goenv_installed() {
    [[ -d "$GOENV_DIR" ]] && [[ -f "$GOENV_DIR/bin/goenv" ]]
}

install_goenv() {
    log_info "Installing goenv..."
    
    if check_goenv_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "goenv is already installed at $GOENV_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    if [[ -d "$GOENV_DIR" ]] && [[ "${FORCE_INSTALL:-}" == "true" ]]; then
        log_warning "Removing existing goenv installation..."
        rm -rf "$GOENV_DIR"
    fi
    
    # Clone goenv
    log_info "Cloning goenv from $GOENV_REPO..."
    if ! git clone "$GOENV_REPO" "$GOENV_DIR"; then
        log_error "Failed to clone goenv"
        return 1
    fi
    
    log_success "goenv installed successfully to $GOENV_DIR"
    
    # Add to PATH for verification
    export GOENV_ROOT="$GOENV_DIR"
    export PATH="$GOENV_DIR/bin:$PATH"
    
    return 0
}

# Main module execution
main_goenv() {
    if ! install_goenv; then
        return 1
    fi
    
    # Verify installation
    if check_goenv_installed; then
        export PATH="$GOENV_DIR/bin:$PATH"
        local version=$("$GOENV_DIR/bin/goenv" --version 2>/dev/null || echo "unknown")
        log_success "goenv installation verified: $version"
        return 0
    else
        log_error "goenv installation could not be verified"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_goenv
fi

