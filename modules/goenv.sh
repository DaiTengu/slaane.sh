#!/usr/bin/env bash
# Module: goenv installation
# Installs goenv (Go version manager)

# Metadata: START
MODULE_NAME="goenv"
MODULE_DESCRIPTION="Go version manager"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="false"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="git_clone"
MODULE_INSTALL_DIRS="$HOME/.goenv"
MODULE_INSTALL_REPO="https://github.com/go-nv/goenv.git"
MODULE_UPDATE_METHOD="git_pull"
MODULE_UPDATE_DIR="$HOME/.goenv"
MODULE_UNINSTALL_DIRS="$HOME/.goenv"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="$HOME/.goenv"
MODULE_TEST_FILES="$HOME/.goenv/bin/goenv"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

GOENV_DIR="$HOME/.goenv"

check_module_installed() {
    [[ -d "$GOENV_DIR" ]] && [[ -f "$GOENV_DIR/bin/goenv" ]]
}

main_module() {
    log_info "Installing goenv..."
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "goenv is already installed at $GOENV_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Use generic git_clone handler
    if ! install_via_git_clone "$MODULE_NAME"; then
        return 1
    fi
    
    log_success "goenv installed successfully"
    
    # Verify installation
    if check_module_installed; then
        export PATH="$GOENV_DIR/bin:$PATH"
        local version=$("$GOENV_DIR/bin/goenv" --version 2>/dev/null || echo "unknown")
        log_success "goenv installation verified: $version"
        return 0
    else
        log_error "goenv installation could not be verified"
        return 1
    fi
}

update_module() {
    update_via_git_pull "$MODULE_NAME"
}

