#!/usr/bin/env bash
# Install helpers for Slaane.sh
# Functions for downloading binaries from GitHub and installing via pipx

# ============================================================================
# GitHub Binary Downloads (via dra)
# ============================================================================

# Download and install binary from GitHub releases using dra
# Usage: install_github_binary "owner/repo"
install_github_binary() {
    local repo="$1"
    
    command -v dra &>/dev/null || {
        log_error "dra not installed - run install_dra first"
        return 1
    }
    
    mkdir -p "$HOME/.local/bin"
    
    # -a = automatic OS/arch detection
    # -i = install (extract and place binary)
    # -o = output destination
    log_info "Downloading $repo via dra..."
    dra download -a -i -o "$HOME/.local/bin/" "$repo"
}

# ============================================================================
# Python Package Installation (via pipx)
# ============================================================================

# Install Python CLI tool via pipx
# Auto-bootstraps pip and pipx if missing
# Usage: try_pipx_install "package-name"
try_pipx_install() {
    local package="${1:-${MODULE_PIPX:-}}"
    [[ -z "$package" ]] && return 1
    
    # Bootstrap pip if missing (works without sudo)
    if ! python3 -m pip --version &>/dev/null; then
        log_info "pip not found, bootstrapping via get-pip.py..."
        curl -sSL https://bootstrap.pypa.io/get-pip.py | python3 - --user || {
            log_error "Failed to bootstrap pip"
            return 1
        }
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Bootstrap pipx if missing
    if ! command -v pipx &>/dev/null; then
        log_info "Installing pipx (Python tool manager)..."
        python3 -m pip install --user pipx || {
            log_error "Failed to install pipx"
            return 1
        }
        export PATH="$HOME/.local/bin:$PATH"
        pipx ensurepath 2>/dev/null || true
    fi
    
    log_info "Installing $package via pipx..."
    pipx install "$package"
}

# Upgrade Python CLI tool via pipx
# Usage: upgrade_pipx_package "package-name"
upgrade_pipx_package() {
    local package="${1:-${MODULE_PIPX:-}}"
    [[ -z "$package" ]] && return 1
    
    command -v pipx &>/dev/null || return 1
    pipx upgrade "$package"
}

# Uninstall Python CLI tool via pipx
# Usage: uninstall_pipx_package "package-name"
uninstall_pipx_package() {
    local package="${1:-${MODULE_PIPX:-}}"
    [[ -z "$package" ]] && return 1
    
    command -v pipx &>/dev/null || return 1
    pipx uninstall "$package"
}
