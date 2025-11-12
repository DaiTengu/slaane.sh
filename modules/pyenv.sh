#!/usr/bin/env bash
# Module: pyenv installation
# Installs pyenv (Python version manager)

# Metadata: START
MODULE_NAME="pyenv"
MODULE_DESCRIPTION="Python version manager"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="false"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="git_clone"
MODULE_INSTALL_DIRS="$HOME/.pyenv"
MODULE_INSTALL_REPO="https://github.com/pyenv/pyenv.git"
MODULE_UPDATE_METHOD="component_command"
MODULE_UPDATE_DIR="$HOME/.pyenv"
MODULE_UNINSTALL_DIRS="$HOME/.pyenv"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="$HOME/.pyenv"
MODULE_TEST_FILES="$HOME/.pyenv/bin/pyenv"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

PYENV_DIR="$HOME/.pyenv"

check_module_installed() {
    [[ -d "$PYENV_DIR" ]] && [[ -f "$PYENV_DIR/bin/pyenv" ]]
}

main_module() {
    log_info "Installing pyenv..."
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "pyenv is already installed at $PYENV_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Use generic git_clone handler
    if ! install_via_git_clone "$MODULE_NAME"; then
        return 1
    fi
    
    # Clone pyenv-virtualenv plugin
    log_info "Installing pyenv-virtualenv plugin..."
    if git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_DIR/plugins/pyenv-virtualenv"; then
        log_success "pyenv-virtualenv plugin installed"
    else
        log_warning "Failed to install pyenv-virtualenv plugin (optional)"
    fi
    
    # Clone pyenv-update plugin
    log_info "Installing pyenv-update plugin..."
    if git clone https://github.com/pyenv/pyenv-update.git "$PYENV_DIR/plugins/pyenv-update"; then
        log_success "pyenv-update plugin installed"
    else
        log_warning "Failed to install pyenv-update plugin (optional)"
    fi
    
    log_success "pyenv installed successfully"
    
    # Verify installation
    if check_module_installed; then
        export PATH="$PYENV_DIR/bin:$PATH"
        local version=$("$PYENV_DIR/bin/pyenv" --version 2>/dev/null || echo "unknown")
        log_success "pyenv installation verified: $version"
        return 0
    else
        log_error "pyenv installation could not be verified"
        return 1
    fi
}

update_module() {
    if [[ ! -d "$PYENV_DIR" ]] || [[ ! -f "$PYENV_DIR/bin/pyenv" ]]; then
        log_error "pyenv is not installed"
        return 1
    fi
    
    export PATH="$PYENV_DIR/bin:$PATH"
    
    # Check if pyenv-update plugin exists
    if [[ -d "$PYENV_DIR/plugins/pyenv-update" ]]; then
        log_info "Running pyenv update..."
        "$PYENV_DIR/bin/pyenv" update
        return $?
    else
        # Fall back to git pull
        log_info "pyenv-update plugin not found, using git pull..."
        update_via_git_pull "$MODULE_NAME"
        return $?
    fi
}

