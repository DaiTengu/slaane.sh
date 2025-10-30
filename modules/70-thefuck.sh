#!/usr/bin/env bash
# Module: thefuck installation
# Installs thefuck (command corrector)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

check_thefuck_installed() {
    command_exists thefuck
}

install_thefuck_via_pip() {
    log_info "Installing thefuck via pip..."
    
    # Check if pip3 is available
    if ! command_exists pip3 && ! command_exists pip; then
        log_error "pip3 or pip is not installed"
        log_info "Please install python3-pip first"
        return 1
    fi
    
    local pip_cmd="pip3"
    if ! command_exists pip3; then
        pip_cmd="pip"
    fi
    
    # Install thefuck for current user
    if $pip_cmd install --user thefuck; then
        log_success "thefuck installed via pip"
        
        # Add to PATH if needed
        if [[ -d "$HOME/.local/bin" ]]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
        return 0
    else
        log_error "Failed to install thefuck via pip"
        return 1
    fi
}

install_thefuck_via_package_manager() {
    log_info "Attempting to install thefuck from package manager..."
    
    local pkg=""
    case "$PKG_MANAGER" in
        apt)
            # Not commonly available in apt repos
            return 1
            ;;
        dnf|yum)
            # Available in some EPEL repos
            pkg="thefuck"
            ;;
        pacman)
            pkg="thefuck"
            ;;
    esac
    
    if [[ -z "$pkg" ]]; then
        return 1
    fi
    
    if run_as_root $PKG_INSTALL "$pkg" 2>/dev/null; then
        log_success "thefuck installed from package manager"
        return 0
    else
        return 1
    fi
}

install_thefuck() {
    log_info "Installing thefuck..."
    
    if check_thefuck_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "thefuck is already installed"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Try package manager first (if available)
    if install_thefuck_via_package_manager; then
        return 0
    fi
    
    # Fall back to pip
    if install_thefuck_via_pip; then
        return 0
    fi
    
    log_error "All thefuck installation methods failed"
    log_info "Install manually with: pip3 install --user thefuck"
    return 1
}

# Main module execution
main_thefuck() {
    if ! install_thefuck; then
        return 1
    fi
    
    # Verify installation
    if check_thefuck_installed; then
        local version=$(thefuck --version 2>/dev/null || echo "unknown")
        log_success "thefuck installation verified: $version"
        return 0
    else
        log_error "thefuck installation could not be verified"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_thefuck
fi

