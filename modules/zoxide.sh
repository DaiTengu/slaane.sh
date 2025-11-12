#!/usr/bin/env bash
# Module: zoxide installation
# Installs zoxide (smart directory jumper)

# Metadata: START
MODULE_NAME="zoxide"
MODULE_DESCRIPTION="Smart directory jumper"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="false"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="custom"
MODULE_INSTALL_DIRS=""
MODULE_UPDATE_METHOD="reinstall"
MODULE_UNINSTALL_DIRS=""
MODULE_UNINSTALL_BINARIES="zoxide"
MODULE_CONFIG_FILES=""
MODULE_TEST_BINARIES="zoxide"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

check_module_installed() {
    command_exists zoxide
}

enable_epel_if_needed() {
    if [[ "$OS_FAMILY" != "rhel" ]]; then
        return 0
    fi
    
    if run_as_root $PKG_MANAGER repolist 2>/dev/null | grep -q epel; then
        log_info "EPEL repository already enabled"
        return 0
    fi
    
    log_info "Enabling EPEL repository..."
    if run_as_root $PKG_INSTALL epel-release 2>/dev/null; then
        log_success "EPEL repository enabled"
        return 0
    else
        log_warning "Failed to enable EPEL repository"
        return 1
    fi
}

install_zoxide_from_package_manager() {
    log_info "Attempting to install zoxide from package manager..."
    
    local pkg=""
    case "$PKG_MANAGER" in
        apt)
            pkg="zoxide"
            ;;
        dnf|yum)
            if ! enable_epel_if_needed; then
                return 1
            fi
            pkg="zoxide"
            ;;
        pacman)
            pkg="zoxide"
            ;;
    esac
    
    if [[ -z "$pkg" ]]; then
        return 1
    fi
    
    if run_as_root $PKG_INSTALL "$pkg" 2>/dev/null; then
        log_success "zoxide installed from package manager"
        return 0
    else
        return 1
    fi
}

install_zoxide_from_official_script() {
    log_info "Installing zoxide from official install script..."
    
    if ! curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
        log_error "Failed to install zoxide from official script"
        return 1
    fi
    
    if [[ -d "$HOME/.local/bin" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    if command_exists zoxide; then
        log_success "zoxide installed from official script"
        return 0
    else
        log_error "zoxide installation verification failed"
        return 1
    fi
}

install_zoxide_from_cargo() {
    log_info "Installing zoxide using cargo..."
    
    if ! command_exists cargo; then
        return 1
    fi
    
    if cargo install zoxide --locked; then
        log_success "zoxide installed via cargo"
        if [[ -d "$HOME/.cargo/bin" ]]; then
            export PATH="$HOME/.cargo/bin:$PATH"
        fi
        return 0
    else
        return 1
    fi
}

main_module() {
    log_info "Installing zoxide..."
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "zoxide is already installed"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Try methods in order of preference
    if install_zoxide_from_package_manager; then
        return 0
    fi
    
    if install_zoxide_from_official_script; then
        return 0
    fi
    
    if command_exists cargo && install_zoxide_from_cargo; then
        return 0
    fi
    
    log_error "All zoxide installation methods failed"
    return 1
}

update_module() {
    # Reinstall to get latest version
    update_via_reinstall "$MODULE_NAME"
}

