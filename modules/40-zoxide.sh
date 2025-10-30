#!/usr/bin/env bash
# Module: zoxide installation
# Installs zoxide (smart directory jumper)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

check_zoxide_installed() {
    command_exists zoxide
}

install_zoxide_from_package_manager() {
    log_info "Attempting to install zoxide from package manager..."
    
    local pkg=""
    case "$PKG_MANAGER" in
        apt)
            # zoxide is available in Ubuntu 21.04+ and Debian 12+
            pkg="zoxide"
            ;;
        dnf|yum)
            # Available in Fedora 35+ and RHEL 9+
            pkg="zoxide"
            ;;
        pacman)
            pkg="zoxide"
            ;;
    esac
    
    if [[ -z "$pkg" ]]; then
        log_info "zoxide not available in package manager, will use cargo"
        return 1
    fi
    
    if run_as_root $PKG_INSTALL "$pkg" 2>/dev/null; then
        log_success "zoxide installed from package manager"
        return 0
    else
        log_info "Package manager installation failed, will try cargo"
        return 1
    fi
}

install_zoxide_from_cargo() {
    log_info "Installing zoxide using cargo..."
    
    if ! command_exists cargo; then
        log_error "cargo is not installed"
        log_info "To install Rust and cargo:"
        log_info "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        log_info "  or install via package manager (e.g., 'cargo' package)"
        return 1
    fi
    
    # Install zoxide using cargo
    if cargo install zoxide --locked; then
        log_success "zoxide installed via cargo"
        
        # Ensure cargo bin is in PATH
        if [[ -d "$HOME/.cargo/bin" ]]; then
            export PATH="$HOME/.cargo/bin:$PATH"
        fi
        
        return 0
    else
        log_error "Failed to install zoxide via cargo"
        return 1
    fi
}

install_zoxide_prebuilt() {
    log_info "Installing zoxide from prebuilt binary..."
    
    local arch=$(uname -m)
    local os="unknown-linux-musl"
    local version="v0.9.4"  # Latest as of creation, adjust as needed
    
    case "$arch" in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        armv7l)
            arch="armv7"
            ;;
        *)
            log_warning "Unsupported architecture for prebuilt binary: $arch"
            return 1
            ;;
    esac
    
    local url="https://github.com/ajeetdsouza/zoxide/releases/download/${version}/zoxide-${version}-${arch}-${os}.tar.gz"
    local tmp_dir=$(mktemp -d)
    
    log_info "Downloading from $url..."
    if ! curl -fsSL "$url" -o "$tmp_dir/zoxide.tar.gz"; then
        log_warning "Failed to download prebuilt binary"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    # Extract
    tar -xzf "$tmp_dir/zoxide.tar.gz" -C "$tmp_dir"
    
    # Install to ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    mv "$tmp_dir/zoxide" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/zoxide"
    
    # Cleanup
    rm -rf "$tmp_dir"
    
    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    
    if command_exists zoxide; then
        log_success "zoxide installed from prebuilt binary"
        return 0
    else
        log_error "zoxide installation verification failed"
        return 1
    fi
}

install_zoxide() {
    log_info "Installing zoxide..."
    
    if check_zoxide_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "zoxide is already installed"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Try methods in order of preference
    # 1. Package manager (fastest, most integrated)
    if install_zoxide_from_package_manager; then
        return 0
    fi
    
    # 2. Prebuilt binary (no compilation needed)
    if install_zoxide_prebuilt; then
        return 0
    fi
    
    # 3. Cargo (requires Rust but works everywhere)
    if install_zoxide_from_cargo; then
        return 0
    fi
    
    log_error "All zoxide installation methods failed"
    log_info "Please install manually:"
    log_info "  - Via package manager if available"
    log_info "  - Via cargo: cargo install zoxide"
    log_info "  - From releases: https://github.com/ajeetdsouza/zoxide/releases"
    return 1
}

# Main module execution
main_zoxide() {
    if ! install_zoxide; then
        return 1
    fi
    
    # Verify installation
    if check_zoxide_installed; then
        local version=$(zoxide --version 2>/dev/null || echo "unknown")
        log_success "zoxide installation verified: $version"
        return 0
    else
        log_error "zoxide installation could not be verified"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_zoxide
fi

