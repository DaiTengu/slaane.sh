#!/usr/bin/env bash
# bat - A cat clone with syntax highlighting and Git integration

MODULE_BIN="bat"
MODULE_PKG_NAME="bat"
MODULE_GITHUB="sharkdp/bat"
MODULE_REPLACES="cat"  # Creates: alias cat='bat'
MODULE_PROJECT_URL="https://github.com/sharkdp/bat"

# No custom install() needed - framework handles everything via:
# - System package (if --global) 
# - GitHub binary download via dra (user-space default)
