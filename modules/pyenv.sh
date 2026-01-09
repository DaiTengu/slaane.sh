#!/usr/bin/env bash
# pyenv - Python version manager

MODULE_DIR="$HOME/.pyenv"
MODULE_REPO="https://github.com/pyenv/pyenv.git"

post_install() {
    # Install useful plugins
    git clone --depth=1 https://github.com/pyenv/pyenv-virtualenv.git \
        "$MODULE_DIR/plugins/pyenv-virtualenv" 2>/dev/null || true
    git clone --depth=1 https://github.com/pyenv/pyenv-update.git \
        "$MODULE_DIR/plugins/pyenv-update" 2>/dev/null || true
}

update() {
    if [[ -d "$MODULE_DIR/plugins/pyenv-update" ]]; then
        "$MODULE_DIR/bin/pyenv" update
    else
        (cd "$MODULE_DIR" && git pull)
        post_install
    fi
}
