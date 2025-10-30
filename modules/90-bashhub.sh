#!/usr/bin/env bash
# Module: bashhub installation
# Installs bashhub (cloud command history) - OPTIONAL

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

BASHHUB_DIR="$HOME/.bashhub"

check_bashhub_installed() {
    [[ -f "$BASHHUB_DIR/bashhub.sh" ]]
}

install_bashhub() {
    log_info "Installing bashhub..."
    
    if check_bashhub_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "bashhub is already installed"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    log_warning "bashhub requires account registration and per-server credentials"
    log_info "Visit https://bashhub.com to create an account"
    
    # Download and run the installer
    log_info "Downloading bashhub installer..."
    if ! curl -fsSL https://bashhub.com/setup | bash; then
        log_error "Failed to install bashhub"
        log_info "You can install manually by visiting https://bashhub.com/setup"
        return 1
    fi
    
    log_success "bashhub installed"
    log_info "Follow the prompts to complete setup with your credentials"
    
    return 0
}

# Main module execution
main_bashhub() {
    log_warning "bashhub is an OPTIONAL component"
    log_info "It requires:"
    log_info "  - Account registration at bashhub.com"
    log_info "  - Per-server authentication credentials"
    log_info ""
    
    if [[ "${WITH_BASHHUB:-}" != "true" ]]; then
        log_info "Skipping bashhub installation (use --with-bashhub to install)"
        return 0
    fi
    
    if ! install_bashhub; then
        log_warning "bashhub installation failed, continuing anyway"
        return 0  # Don't fail the whole installation
    fi
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_bashhub
fi

