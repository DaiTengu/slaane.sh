#!/usr/bin/env bash
# pipx - Install and run Python applications in isolated environments

MODULE_BIN="pipx"
MODULE_PKG_NAME="pipx"
MODULE_PROJECT_URL="https://github.com/pypa/pipx"

# pipx is special - it bootstraps itself via pip if system package isn't available
install() {
    # Try system package first (if sudo available and preferred)
    if [[ "${PREFER_GLOBAL:-}" == "true" ]] && [[ -n "$PKG_INSTALL" ]]; then
        if RUN_AS_ROOT_OPERATION="install pipx" run_as_root $PKG_INSTALL pipx; then
            return 0
        fi
        log_warning "System package install failed, trying pip..."
    fi
    
    # Fallback: pip install --user (no sudo needed)
    python3 -m pip install --user pipx || {
        log_error "Failed to install pipx via pip"
        return 1
    }
    
    # Ensure ~/.local/bin is in PATH
    export PATH="$HOME/.local/bin:$PATH"
    return 0
}

post_install() {
    pipx ensurepath 2>/dev/null || true
}
