#!/usr/bin/env bash
# thefuck - Command correction when you mistype

MODULE_BIN="thefuck"
MODULE_PKG_NAME="thefuck"
MODULE_PIP="thefuck"

# thefuck uses the deprecated 'imp' module, removed in Python 3.12+
# Try system package first when --global, then pip (skip pip on 3.12+)
install() {
    if [[ "${PREFER_GLOBAL:-}" == "true" ]] && install_system_package "$MODULE_PKG_NAME"; then
        return 0
    fi
    if python3 -c 'import sys; sys.exit(0 if (sys.version_info.major, sys.version_info.minor) >= (3, 12) else 1)' 2>/dev/null; then
        log_warning "thefuck is incompatible with Python 3.12+ (imp module removed). Skipping."
        return 1
    fi
    install_pip_package "$MODULE_PIP"
}
