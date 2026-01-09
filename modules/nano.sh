#!/usr/bin/env bash
# nano - Nano editor with syntax highlighting

MODULE_DIR="$HOME/.nano"
MODULE_BIN="nano"
MODULE_PKG_NAME="nano"
MODULE_REPO="https://github.com/galenguyer/nano-syntax-highlighting.git"

post_install() {
    if ! grep -q "include.*\.nano" "$HOME/.nanorc" 2>/dev/null; then
        echo 'include "~/.nano/*.nanorc"' >> "$HOME/.nanorc"
    fi
}
