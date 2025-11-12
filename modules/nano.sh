#!/usr/bin/env bash
# Module: nano syntax highlighting installation
# Installs nano syntax highlighting from galenguyer/nano-syntax-highlighting

# Metadata: START
MODULE_NAME="nano"
MODULE_DESCRIPTION="Nano syntax highlighting"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="false"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="custom"
MODULE_INSTALL_DIRS="$HOME/.nano"
MODULE_UPDATE_METHOD="reinstall"
MODULE_UNINSTALL_DIRS="$HOME/.nano"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="$HOME/.nano"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

NANO_SYNTAX_INSTALLER_URL="https://raw.githubusercontent.com/galenguyer/nano-syntax-highlighting/master/install.sh"
NANO_SYNTAX_DIR="$HOME/.nano"

check_module_installed() {
    [[ -d "$NANO_SYNTAX_DIR" ]] && [[ -n "$(ls -A "$NANO_SYNTAX_DIR"/*.nanorc 2>/dev/null)" ]]
}

install_nano_if_needed() {
    if command_exists nano; then
        log_info "nano is already installed"
        return 0
    fi
    
    if [[ "${INSTALL_PREREQS:-}" != "true" ]]; then
        log_warning "nano is not installed"
        log_info "Syntax highlighting will be installed but won't work until nano is installed"
        log_info "Run with --install-prereqs to automatically install nano"
        return 0
    fi
    
    log_info "Installing nano..."
    
    if [[ "$PKG_MANAGER" == "unknown" ]]; then
        log_warning "Cannot determine package manager. Please install nano manually"
        return 0
    fi
    
    local nano_pkg=$(get_package_names "nano")
    if [[ -z "$nano_pkg" ]]; then
        nano_pkg="nano"
    fi
    
    log_info "Installing $nano_pkg..."
    if run_as_root $PKG_INSTALL "$nano_pkg"; then
        log_success "nano installed successfully"
        return 0
    else
        log_warning "Failed to install nano, but continuing with syntax highlighting installation"
        return 0
    fi
}

main_module() {
    # Install nano if needed (only if --install-prereqs is set)
    install_nano_if_needed
    
    # Install syntax highlighting
    log_info "Installing nano syntax highlighting..."
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "Nano syntax highlighting is already installed at $NANO_SYNTAX_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Check for dependencies
    local missing_deps=()
    if ! command_exists unzip; then
        missing_deps+=("unzip")
    fi
    if ! command_exists wget; then
        missing_deps+=("wget")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        if [[ "${INSTALL_PREREQS:-}" == "true" ]]; then
            log_info "Installing missing dependencies: ${missing_deps[*]}..."
            if [[ "$PKG_MANAGER" != "unknown" ]]; then
                local to_install=()
                for dep in "${missing_deps[@]}"; do
                    local dep_pkg=$(get_package_names "$dep")
                    if [[ -z "$dep_pkg" ]]; then
                        dep_pkg="$dep"
                    fi
                    to_install+=("$dep_pkg")
                done
                if ! run_as_root $PKG_INSTALL "${to_install[@]}"; then
                    log_error "Failed to install dependencies: ${missing_deps[*]}"
                    return 1
                fi
            else
                log_error "Cannot determine package manager. Please install manually: ${missing_deps[*]}"
                return 1
            fi
        else
            log_error "Missing required dependencies: ${missing_deps[*]}"
            log_info "Run with --install-prereqs to automatically install them"
            return 1
        fi
    fi
    
    # Download and run the installer
    log_info "Downloading and running nano syntax highlighting installer..."
    if ! curl -fsSL "$NANO_SYNTAX_INSTALLER_URL" | bash; then
        log_error "Failed to install nano syntax highlighting"
        return 1
    fi
    
    # Verify installation
    if check_module_installed; then
        log_success "Nano syntax highlighting installed successfully"
        if command_exists nano; then
            log_info "Nano version: $(nano --version | head -n1)"
        fi
        return 0
    else
        log_warning "Installation completed but syntax files not found. This is okay if nano isn't installed yet."
        return 0
    fi
}

update_module() {
    # Reinstall to get latest syntax files
    update_via_reinstall "$MODULE_NAME"
}

