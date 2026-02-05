#!/usr/bin/env bash
# rustup - Rust toolchain installer and version manager

MODULE_BIN="cargo"
MODULE_DIR="$HOME/.cargo"
MODULE_CHECK_FILE="$HOME/.cargo/bin/cargo"
MODULE_PROJECT_URL="https://rustup.rs/"

# rustup has its own installer - doesn't use dra or system packages
install() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    export PATH="$HOME/.cargo/bin:$PATH"
}

# Custom update function
update() {
    if command -v rustup &>/dev/null; then
        rustup update
    else
        log_error "rustup not found"
        return 1
    fi
}

# Check if installed
is_installed() {
    [[ -f "$HOME/.cargo/bin/cargo" ]]
}
