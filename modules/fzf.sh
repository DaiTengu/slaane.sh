#!/usr/bin/env bash
# fzf - Fuzzy finder for command-line

MODULE_DIR="$HOME/.fzf"
MODULE_REPO="https://github.com/junegunn/fzf.git"
MODULE_BIN="fzf"
MODULE_CORE=true

post_install() {
    # Run fzf install script to download binary
    "$MODULE_DIR/install" --bin --no-update-rc --no-bash --no-zsh --no-fish
}

update() {
    (cd "$MODULE_DIR" && git pull) || return 1
    post_install
}
