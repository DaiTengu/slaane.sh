#!/usr/bin/env bash
# Module: fzf installation
# Installs fzf (fuzzy finder) with architecture detection

# Metadata: START
MODULE_NAME="fzf"
MODULE_DESCRIPTION="Fuzzy finder for command-line"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="true"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="custom"
MODULE_INSTALL_DIRS="$HOME/.fzf"
MODULE_UPDATE_METHOD="git_pull"
MODULE_UPDATE_DIR="$HOME/.fzf"
MODULE_UNINSTALL_DIRS="$HOME/.fzf"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="$HOME/.fzf"
MODULE_TEST_BINARIES="fzf"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

FZF_REPO="https://github.com/junegunn/fzf.git"
FZF_DIR="$HOME/.fzf"

check_module_installed() {
    command_exists fzf && [[ -d "$FZF_DIR" ]]
}

main_module() {
    log_info "Installing fzf..."
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "fzf is already installed"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    if [[ -d "$FZF_DIR" ]] && [[ "${FORCE_INSTALL:-}" == "true" ]]; then
        log_warning "Removing existing fzf installation..."
        rm -rf "$FZF_DIR"
    fi
    
    # Clone fzf
    log_info "Cloning fzf from $FZF_REPO..."
    if ! git clone --depth=1 "$FZF_REPO" "$FZF_DIR"; then
        log_error "Failed to clone fzf"
        return 1
    fi
    
    # Install fzf (this downloads the appropriate binary for the architecture)
    log_info "Installing fzf (will detect architecture automatically)..."
    cd "$FZF_DIR" || return 1
    
    # Run install with options:
    # --bin: only install binary (bash integration handled by bash-it)
    # --no-update-rc: don't modify shell rc files (we handle this)
    if ! ./install --bin --no-update-rc; then
        log_error "Failed to install fzf"
        return 1
    fi
    
    # Verify installation
    if [[ -f "$FZF_DIR/bin/fzf" ]]; then
        log_success "fzf installed successfully"
        
        # Add to PATH in current session for verification
        export PATH="$FZF_DIR/bin:$PATH"
        
        # Show version info
        local fzf_version=$(fzf --version | head -n1)
        local arch=$(uname -m)
        log_info "Installed: $fzf_version (architecture: $arch)"
        
        return 0
    else
        log_error "fzf binary not found after installation"
        return 1
    fi
}

update_module() {
    update_via_git_pull "$MODULE_NAME"
    if [[ $? -eq 0 ]]; then
        # Re-run install script to update binary
        log_info "Updating fzf binary..."
        cd "$FZF_DIR" && ./install --bin --no-update-rc
        return $?
    fi
    return 1
}

