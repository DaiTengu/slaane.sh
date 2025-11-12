#!/usr/bin/env bash
# Module: ble.sh installation
# Installs ble.sh (Bash Line Editor) with syntax highlighting and advanced features

# Metadata: START
MODULE_NAME="blesh"
MODULE_DESCRIPTION="Bash Line Editor with syntax highlighting and advanced features"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="true"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="custom"
MODULE_INSTALL_DIRS="$HOME/.local/src/blesh ${XDG_DATA_HOME:-$HOME/.local/share}/blesh"
MODULE_UPDATE_METHOD="git_pull"
MODULE_UPDATE_DIR="$HOME/.local/src/blesh"
MODULE_UNINSTALL_DIRS="$HOME/.local/src/blesh ${XDG_DATA_HOME:-$HOME/.local/share}/blesh"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="${XDG_DATA_HOME:-$HOME/.local/share}/blesh"
MODULE_TEST_FILES="${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh"
# Metadata: END

# Bootstrap module environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/module-api.sh"
bootstrap_module

BLESH_REPO="https://github.com/akinomyoga/ble.sh.git"
BLESH_SRC_DIR="$HOME/.local/src/blesh"
BLESH_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/blesh"

check_module_installed() {
    [[ -f "$BLESH_INSTALL_DIR/ble.sh" ]]
}

main_module() {
    log_info "Installing ble.sh..."
    
    if check_module_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "ble.sh is already installed at $BLESH_INSTALL_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Create source directory
    mkdir -p "$(dirname "$BLESH_SRC_DIR")"
    
    if [[ -d "$BLESH_SRC_DIR" ]] && [[ "${FORCE_INSTALL:-}" == "true" ]]; then
        log_warning "Removing existing ble.sh source..."
        rm -rf "$BLESH_SRC_DIR"
    fi
    
    # Clone ble.sh
    log_info "Cloning ble.sh from $BLESH_REPO..."
    if ! git clone --recursive --depth=1 "$BLESH_REPO" "$BLESH_SRC_DIR"; then
        log_error "Failed to clone ble.sh"
        return 1
    fi
    
    # Build and install
    log_info "Building and installing ble.sh..."
    cd "$BLESH_SRC_DIR" || return 1
    
    if ! make install PREFIX="$HOME/.local"; then
        log_error "Failed to build/install ble.sh"
        return 1
    fi
    
    log_success "ble.sh installed successfully to $BLESH_INSTALL_DIR"
    
    # Check if .blerc needs to be copied
    if [[ -f "$SCRIPT_DIR/config/blerc" ]] && [[ ! -f "$HOME/.blerc" ]]; then
        log_info "Copying .blerc configuration..."
        cp "$SCRIPT_DIR/config/blerc" "$HOME/.blerc"
        log_success ".blerc configuration installed"
    elif [[ -f "$HOME/.blerc" ]]; then
        log_info ".blerc already exists, not overwriting"
    fi
    
    return 0
}

update_module() {
    if [[ ! -d "$BLESH_SRC_DIR" ]]; then
        log_error "ble.sh source directory not found"
        return 1
    fi
    
    log_info "Updating ble.sh..."
    
    # Pull latest changes
    if ! (cd "$BLESH_SRC_DIR" && git pull); then
        log_error "Failed to update ble.sh source"
        return 1
    fi
    
    # Rebuild and reinstall
    log_info "Rebuilding ble.sh..."
    if ! (cd "$BLESH_SRC_DIR" && make install PREFIX="$HOME/.local"); then
        log_error "Failed to rebuild ble.sh"
        return 1
    fi
    
    log_success "ble.sh updated successfully"
    return 0
}

