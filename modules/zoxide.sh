#!/usr/bin/env bash
# zoxide - Smart directory jumper (smarter cd)

MODULE_BIN="zoxide"

is_installed() {
    command_exists zoxide
}

install() {
    # Try binary download first (no sudo needed)
    if install_from_binary; then
        return 0
    fi
    
    # Try official install script
    if install_from_script; then
        return 0
    fi
    
    # Try package manager (may need sudo)
    if install_from_package_manager; then
        return 0
    fi
    
    return 1
}

install_from_binary() {
    local arch=$(uname -m)
    local binary=""
    
    case "$arch" in
        x86_64)  binary="zoxide-x86_64-unknown-linux-musl" ;;
        aarch64) binary="zoxide-aarch64-unknown-linux-musl" ;;
        armv7l)  binary="zoxide-armv7-unknown-linux-musleabihf" ;;
        *) return 1 ;;
    esac
    
    mkdir -p "$HOME/.local/bin"
    local url="https://github.com/ajeetdsouza/zoxide/releases/latest/download/${binary}.tar.gz"
    
    if curl -sSfL "$url" | tar xz -C "$HOME/.local/bin/" zoxide 2>/dev/null; then
        chmod +x "$HOME/.local/bin/zoxide"
        export PATH="$HOME/.local/bin:$PATH"
        return 0
    fi
    return 1
}

install_from_script() {
    if curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
        export PATH="$HOME/.local/bin:$PATH"
        return 0
    fi
    return 1
}

install_from_package_manager() {
    case "$PKG_MANAGER" in
        apt|dnf|yum|pacman)
            # Enable EPEL on RHEL family
            if [[ "$OS_FAMILY" == "rhel" ]]; then
                run_as_root $PKG_INSTALL epel-release 2>/dev/null || true
            fi
            run_as_root $PKG_INSTALL zoxide 2>/dev/null
            return $?
            ;;
    esac
    return 1
}

uninstall() {
    rm -f "$HOME/.local/bin/zoxide"
    rm -rf "$HOME/.local/share/zoxide"
}
