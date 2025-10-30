#!/usr/bin/env bash
# Module: ble.sh installation
# Installs ble.sh (Bash Line Editor) with syntax highlighting and advanced features

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

BLESH_REPO="https://github.com/akinomyoga/ble.sh.git"
BLESH_SRC_DIR="$HOME/.local/src/blesh"
BLESH_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/blesh"

check_blesh_installed() {
    [[ -f "$BLESH_INSTALL_DIR/ble.sh" ]]
}

install_blesh() {
    log_info "Installing ble.sh..."
    
    if check_blesh_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "ble.sh is already installed at $BLESH_INSTALL_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Create source directory
    mkdir -p "$(dirname "$BLESH_SRC_DIR")"
    
    if [[ -d "$BLESH_SRC_DIR" ]] && [[ "${FORCE_INSTALL:-}" == "true" ]]; then
        log_warning "Removing existing ble.sh source..."
        rm -rf "$BLESH_SRC_DIR"
    fi
    
    # Clone ble.sh
    log_info "Cloning ble.sh from $BLESH_REPO..."
    if ! git clone --recursive --depth=1 "$BLESH_REPO" "$BLESH_SRC_DIR"; then
        log_error "Failed to clone ble.sh"
        return 1
    fi
    
    # Build and install
    log_info "Building and installing ble.sh..."
    cd "$BLESH_SRC_DIR" || return 1
    
    if ! make install PREFIX="$HOME/.local"; then
        log_error "Failed to build/install ble.sh"
        return 1
    fi
    
    log_success "ble.sh installed successfully to $BLESH_INSTALL_DIR"
    
    # Check if .blerc needs to be copied
    if [[ -f "$SCRIPT_DIR/../config/blerc" ]] && [[ ! -f "$HOME/.blerc" ]]; then
        log_info "Copying .blerc configuration..."
        cp "$SCRIPT_DIR/../config/blerc" "$HOME/.blerc"
        log_success ".blerc configuration installed"
    elif [[ -f "$HOME/.blerc" ]]; then
        log_info ".blerc already exists, not overwriting"
    fi
    
    return 0
}

configure_blesh_integration() {
    log_info "Configuring ble.sh integration with fzf..."
    
    # The integration is handled by bash-it's blesh plugin
    # which automatically loads fzf integrations if fzf plugin is enabled
    # This is already configured in bash-it-components
    
    log_success "ble.sh will integrate with fzf via bash-it plugin"
    return 0
}

# Main module execution
main_blesh() {
    if ! install_blesh; then
        return 1
    fi
    
    configure_blesh_integration
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_blesh
fi

