#!/usr/bin/env bash
# Module: thefuck installation
# Installs thefuck (command corrector)

# Metadata: START
MODULE_NAME="thefuck"
MODULE_DESCRIPTION="Command corrector"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="false"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="custom"
MODULE_INSTALL_DIRS=""
MODULE_UPDATE_METHOD="pip_upgrade"
MODULE_UNINSTALL_DIRS=""
MODULE_UNINSTALL_BINARIES="thefuck"
MODULE_UNINSTALL_PIP_PACKAGES="thefuck"
MODULE_CONFIG_FILES="$HOME/.config/thefuck"
MODULE_TEST_BINARIES="thefuck"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

check_module_installed() {
    command_exists thefuck
}

get_python_pip() {
    # Try to find pip, preferring pyenv's Python if available
    if [[ -d "$HOME/.pyenv" ]] && [[ -f "$HOME/.pyenv/bin/pyenv" ]]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path 2>/dev/null)" || true
        
        local pyenv_version=$(pyenv version-name 2>/dev/null)
        if [[ -n "$pyenv_version" ]] && [[ "$pyenv_version" != "system" ]]; then
            echo "pip"
            return 0
        fi
    fi
    
    if command_exists pip3; then
        echo "pip3"
        return 0
    elif command_exists pip; then
        echo "pip"
        return 0
    fi
    
    return 1
}

install_thefuck_via_package_manager() {
    log_info "Attempting to install thefuck from package manager..."
    
    local pkg=""
    case "$PKG_MANAGER" in
        dnf|yum)
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

install_thefuck_via_pip() {
    log_info "Installing thefuck via pip..."
    
    local pip_cmd
    if ! pip_cmd=$(get_python_pip); then
        log_warning "No pip found (neither from pyenv nor system)"
        log_info "Attempting to install python3-pip..."
        
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
    
    if $pip_cmd install --user thefuck; then
        log_success "thefuck installed via $pip_cmd"
        if [[ -d "$HOME/.local/bin" ]]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
        return 0
    else
        log_error "Failed to install thefuck via pip"
        return 1
    fi
}

main_module() {
    log_info "Installing thefuck..."
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "thefuck is already installed"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Prefer global install if requested
    if [[ "${PREFER_GLOBAL:-false}" == "true" ]]; then
        if install_thefuck_via_package_manager; then
            return 0
        fi
    fi
    
    # Try pip first (local install with --user)
    if install_thefuck_via_pip; then
        return 0
    fi
    
    # Fall back to package manager if pip failed
    if install_thefuck_via_package_manager; then
        return 0
    fi
    
    log_error "All thefuck installation methods failed"
    return 1
}

update_module() {
    update_via_pip_upgrade "$MODULE_NAME"
}

