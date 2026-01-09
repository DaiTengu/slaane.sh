#!/usr/bin/env bash
# bashhub - Cloud command history (requires account at bashhub.com)

MODULE_DIR="$HOME/.bashhub"
MODULE_SCRIPT="https://bashhub.com/setup"
MODULE_OPTIONAL=true

is_installed() {
    [[ -f "$MODULE_DIR/bashhub.sh" ]]
}

install() {
    log_warning "bashhub requires account registration at bashhub.com"
    log_info "Follow the interactive prompts to complete setup"
    
    curl -fsSL "$MODULE_SCRIPT" | bash
}
