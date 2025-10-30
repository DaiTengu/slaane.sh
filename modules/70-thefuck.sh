#!/usr/bin/env bash
# Module: thefuck installation
# Installs thefuck (command corrector)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

check_thefuck_installed() {
    command_exists thefuck
}

get_python_pip() {
    # Try to find pip, preferring pyenv's Python if available
    
    # First, check if pyenv is installed and has a Python version
    if [[ -d "$HOME/.pyenv" ]] && [[ -f "$HOME/.pyenv/bin/pyenv" ]]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path 2>/dev/null)" || true
        
        # Check if pyenv has any Python version installed
        local pyenv_version=$(pyenv version-name 2>/dev/null)
        if [[ -n "$pyenv_version" ]] && [[ "$pyenv_version" != "system" ]]; then
            log_info "Using Python from pyenv: $pyenv_version"
            echo "pip"
            return 0
        fi
        
        # Try to install system Python version via pyenv
        log_info "pyenv detected but no Python installed, installing system Python version..."
        local system_python_version=$(python3 --version 2>/dev/null | awk '{print $2}')
        if [[ -n "$system_python_version" ]]; then
            log_info "Detecting system Python version: $system_python_version"
            # Just use system Python's pip instead of installing via pyenv
            if command_exists pip3; then
                echo "pip3"
                return 0
            fi
        fi
    fi
    
    # Fall back to system pip
    if command_exists pip3; then
        log_info "Using system pip3"
        echo "pip3"
        return 0
    elif command_exists pip; then
        log_info "Using system pip"
        echo "pip"
        return 0
    fi
    
    # No pip available
    return 1
}

install_thefuck_via_pip() {
    log_info "Installing thefuck via pip..."
    
    # Get appropriate pip command
    local pip_cmd
    if ! pip_cmd=$(get_python_pip); then
        log_warning "No pip found (neither from pyenv nor system)"
        log_info "Attempting to install python3-pip..."
        
        # Try to install python3-pip using package manager
        local pip_pkg=$(get_package_names "python3-pip")
        if [[ -n "$pip_pkg" ]]; then
            if run_as_root $PKG_INSTALL $pip_pkg 2>/dev/null; then
                log_success "python3-pip installed"
                pip_cmd="pip3"
            else
                log_error "Failed to install python3-pip"
                return 1
            fi
        else
            log_error "Cannot determine python3-pip package name"
            return 1
        fi
    fi
    
    # Install thefuck for current user
    if $pip_cmd install --user thefuck; then
        log_success "thefuck installed via $pip_cmd"
        
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

