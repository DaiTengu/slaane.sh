#!/usr/bin/env bash
# thefuck - Command correction when you mistype

MODULE_BIN="thefuck"

is_installed() {
    command_exists thefuck
}

install() {
    # Try pip install (user-local, no sudo)
    local pip_cmd=""
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    fi
    
    if [[ -n "$pip_cmd" ]]; then
        if $pip_cmd install --user thefuck; then
            return 0
        fi
    fi
    
    # Try package manager
    case "$PKG_MANAGER" in
        apt)
            run_as_root apt-get install -y thefuck 2>/dev/null && return 0
            ;;
        dnf|yum)
            run_as_root $PKG_INSTALL thefuck 2>/dev/null && return 0
            ;;
        pacman)
            run_as_root pacman -S --noconfirm thefuck 2>/dev/null && return 0
            ;;
    esac
    
    return 1
}

update() {
    local pip_cmd=""
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        return 1
    fi
    
    $pip_cmd install --user --upgrade thefuck
}

uninstall() {
    local pip_cmd=""
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        return 1
    fi
    
    $pip_cmd uninstall -y thefuck
}
