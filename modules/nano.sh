#!/usr/bin/env bash
# nano - Nano editor with syntax highlighting

MODULE_DIR="$HOME/.nano"
MODULE_BIN="nano"
MODULE_PKG_NAME="nano"
MODULE_REPO="https://github.com/galenguyer/nano-syntax-highlighting.git"

post_install() {
    # Ensure syntax-highlighting repo is present even when nano was already on
    # PATH (in which case the framework's MODULE_REPO clone step was skipped).
    if [[ ! -d "$MODULE_DIR" ]]; then
        git clone --depth=1 "$MODULE_REPO" "$MODULE_DIR" || return 1
    fi

    if ! grep -q "include.*\.nano" "$HOME/.nanorc" 2>/dev/null; then
        echo 'include "~/.nano/*.nanorc"' >> "$HOME/.nanorc"
    fi
}
