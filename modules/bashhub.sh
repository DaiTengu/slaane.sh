#!/usr/bin/env bash
# Module: bashhub installation
# Installs bashhub (cloud command history) - OPTIONAL

# Metadata: START
MODULE_NAME="bashhub"
MODULE_DESCRIPTION="Cloud command history storage"
MODULE_ENABLED_BY_DEFAULT="false"
MODULE_IS_CORE="false"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="download_script"
MODULE_INSTALL_DIRS="$HOME/.bashhub"
MODULE_INSTALL_REPO="https://bashhub.com/setup"
MODULE_UPDATE_METHOD="none"
MODULE_UNINSTALL_DIRS="$HOME/.bashhub"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="$HOME/.bashhub"
MODULE_TEST_FILES="$HOME/.bashhub/bashhub.sh"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

BASHHUB_DIR="$HOME/.bashhub"

check_module_installed() {
    [[ -f "$BASHHUB_DIR/bashhub.sh" ]]
}

main_module() {
    if [[ "${WITH_BASHHUB:-}" != "true" ]]; then
        log_info "Skipping bashhub installation (use --with-bashhub to install)"
        return 0
    fi
    
    log_warning "bashhub requires account registration and per-server credentials"
    log_info "Visit https://bashhub.com to create an account"
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "bashhub is already installed"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Use generic download_script handler
    if install_via_download_script "$MODULE_NAME"; then
        log_success "bashhub installed"
        log_info "Follow the prompts to complete setup with your credentials"
        return 0
    else
        log_error "Failed to install bashhub"
        return 1
    fi
}

