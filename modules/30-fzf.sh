#!/usr/bin/env bash
# Module: fzf installation
# Installs fzf (fuzzy finder) with architecture detection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

FZF_REPO="https://github.com/junegunn/fzf.git"
FZF_DIR="$HOME/.fzf"

check_fzf_installed() {
    command_exists fzf && [[ -d "$FZF_DIR" ]]
}

install_fzf() {
    log_info "Installing fzf..."
    
    if check_fzf_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
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

# Main module execution
main_fzf() {
    if ! install_fzf; then
        return 1
    fi
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_fzf
fi

