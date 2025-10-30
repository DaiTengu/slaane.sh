#!/usr/bin/env bash
# Module: pyenv installation
# Installs pyenv (Python version manager)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

PYENV_REPO="https://github.com/pyenv/pyenv.git"
PYENV_DIR="${PYENV_ROOT:-$HOME/.pyenv}"

check_pyenv_installed() {
    [[ -d "$PYENV_DIR" ]] && [[ -f "$PYENV_DIR/bin/pyenv" ]]
}

install_pyenv_dependencies() {
    log_info "Checking pyenv build dependencies..."
    
    local deps=()
    
    case "$OS_FAMILY" in
        debian)
            deps=(
                "build-essential" "libssl-dev" "zlib1g-dev"
                "libbz2-dev" "libreadline-dev" "libsqlite3-dev"
                "curl" "git" "libncursesw5-dev" "xz-utils"
                "tk-dev" "libxml2-dev" "libxmlsec1-dev" "libffi-dev" "liblzma-dev"
            )
            ;;
        rhel)
            deps=(
                "gcc" "make" "patch" "zlib-devel" "bzip2" "bzip2-devel"
                "readline-devel" "sqlite" "sqlite-devel" "openssl-devel"
                "tk-devel" "libffi-devel" "xz-devel"
            )
            ;;
        arch)
            deps=(
                "base-devel" "openssl" "zlib" "xz" "tk"
            )
            ;;
    esac
    
    if [[ ${#deps[@]} -eq 0 ]]; then
        log_warning "No package list defined for $OS_FAMILY, skipping dependency check"
        return 0
    fi
    
    local missing=()
    for dep in "${deps[@]}"; do
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            if ! dpkg -l "$dep" 2>/dev/null | grep -q "^ii"; then
                missing+=("$dep")
            fi
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Missing build dependencies: ${missing[*]}"
        log_info "Install with: sudo $PKG_INSTALL ${missing[*]}"
        log_info "Pyenv will work but Python compilation may fail without these"
    else
        log_success "All pyenv build dependencies are installed"
    fi
    
    return 0
}

install_pyenv() {
    log_info "Installing pyenv..."
    
    if check_pyenv_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "pyenv is already installed at $PYENV_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Check dependencies
    install_pyenv_dependencies
    
    if [[ -d "$PYENV_DIR" ]] && [[ "${FORCE_INSTALL:-}" == "true" ]]; then
        log_warning "Removing existing pyenv installation..."
        rm -rf "$PYENV_DIR"
    fi
    
    # Clone pyenv
    log_info "Cloning pyenv from $PYENV_REPO..."
    if ! git clone "$PYENV_REPO" "$PYENV_DIR"; then
        log_error "Failed to clone pyenv"
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
    
    log_success "pyenv installed successfully to $PYENV_DIR"
    
    # Add to PATH for verification
    export PYENV_ROOT="$PYENV_DIR"
    export PATH="$PYENV_DIR/bin:$PATH"
    
    return 0
}

# Main module execution
main_pyenv() {
    if ! install_pyenv; then
        return 1
    fi
    
    # Verify installation
    if check_pyenv_installed; then
        export PATH="$PYENV_DIR/bin:$PATH"
        local version=$("$PYENV_DIR/bin/pyenv" --version 2>/dev/null || echo "unknown")
        log_success "pyenv installation verified: $version"
        return 0
    else
        log_error "pyenv installation could not be verified"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_pyenv
fi

