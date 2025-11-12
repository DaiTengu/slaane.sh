#!/usr/bin/env bash
# Module Handlers - Generic install/update/uninstall/test handlers for modules

# Ensure SCRIPT_DIR is set (this should be set by the caller)
# If not set, try to determine from BASH_SOURCE or assume we're in lib/ directory
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    # Try to get from the calling script's directory
    local caller_dir=""
    if [[ -n "${BASH_SOURCE[1]:-}" ]] && [[ -f "${BASH_SOURCE[1]}" ]]; then
        caller_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)" 2>/dev/null || true
    fi
    if [[ -n "$caller_dir" ]] && [[ -f "$caller_dir/lib/common.sh" ]]; then
        SCRIPT_DIR="$caller_dir"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
fi

# Source required libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/module-api.sh"

# ============================================================================
# Installation Handlers
# ============================================================================

# Install module via git clone
install_via_git_clone() {
    local module_name="$1"
    
    if [[ -z "${MODULE_INSTALL_REPO:-}" ]]; then
        log_error "MODULE_INSTALL_REPO not set for module $module_name"
        return 1
    fi
    
    if [[ -z "${MODULE_INSTALL_DIRS:-}" ]]; then
        log_error "MODULE_INSTALL_DIRS not set for module $module_name"
        return 1
    fi
    
    local install_dir="${MODULE_INSTALL_DIRS%% *}"  # Use first directory
    local repo="${MODULE_INSTALL_REPO}"
    local args="${MODULE_INSTALL_ARGS:-}"
    
    # Check if already installed
    if [[ -d "$install_dir" ]] && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "Directory already exists: $install_dir"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    # Remove existing if forcing
    if [[ -d "$install_dir" ]] && [[ "${FORCE_INSTALL:-}" == "true" ]]; then
        log_info "Removing existing installation: $install_dir"
        rm -rf "$install_dir"
    fi
    
    log_info "Cloning $repo to $install_dir..."
    if [[ -n "$args" ]]; then
        if ! git clone $args "$repo" "$install_dir"; then
            log_error "Failed to clone repository"
            return 1
        fi
    else
        if ! git clone "$repo" "$install_dir"; then
            log_error "Failed to clone repository"
            return 1
        fi
    fi
    
    log_success "Git clone completed"
    return 0
}

# Install module via pip
install_via_pip() {
    local module_name="$1"
    local package_name="${MODULE_NAME:-$module_name}"
    
    # Detect pip command (prefer pyenv's pip if available)
    local pip_cmd=""
    if [[ -d "$HOME/.pyenv" ]] && [[ -f "$HOME/.pyenv/bin/pyenv" ]]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path 2>/dev/null)" || true
        pip_cmd="pip"
    elif command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        log_error "pip not found. Please install pip first."
        return 1
    fi
    
    log_info "Installing $package_name via $pip_cmd..."
    if $pip_cmd install --user "$package_name"; then
        log_success "Installed via pip"
        return 0
    else
        log_error "Failed to install via pip"
        return 1
    fi
}

# Install module via package manager
install_via_package_manager() {
    local module_name="$1"
    
    # Package name is usually the module name, but modules can override
    local pkg_name="${MODULE_NAME:-$module_name}"
    
    if [[ "$PKG_MANAGER" == "unknown" ]]; then
        log_error "Cannot determine package manager"
        return 1
    fi
    
    # Get package name from common.sh if available
    local pkg=$(get_package_names "$pkg_name" 2>/dev/null || echo "$pkg_name")
    
    log_info "Installing $pkg via package manager..."
    if run_as_root $PKG_INSTALL "$pkg"; then
        log_success "Installed via package manager"
        return 0
    else
        log_error "Failed to install via package manager"
        return 1
    fi
}

# Install module via download script (curl|bash)
# WARNING: This executes remote scripts without verification
# Consider using checksums or other verification methods for production use
install_via_download_script() {
    local module_name="$1"
    
    if [[ -z "${MODULE_INSTALL_REPO:-}" ]]; then
        log_error "MODULE_INSTALL_REPO (script URL) not set for module $module_name"
        return 1
    fi
    
    local script_url="${MODULE_INSTALL_REPO}"
    
    log_warning "Downloading and executing remote script from: $script_url"
    log_warning "This script will be executed without verification. Ensure you trust the source."
    
    log_info "Downloading and running installer script..."
    if curl -fsSL "$script_url" | bash; then
        log_success "Installer script completed"
        return 0
    else
        log_error "Installer script failed for module $module_name"
        log_error "URL: $script_url"
        return 1
    fi
}

# Generic module installer
# Handles installation based on MODULE_INSTALL_METHOD
install_module_generic() {
    local module_name="$1"
    
    # Load module metadata
    if ! load_module_metadata "$module_name"; then
        log_error "Cannot install module $module_name: metadata not found"
        log_error "Suggestion: Check that modules/${module_name}.sh exists and contains valid metadata"
        return 1
    fi
    
    # Validate metadata
    if ! validate_module_metadata "$module_name"; then
        log_error "Cannot install module $module_name: invalid metadata"
        log_error "Suggestion: Fix metadata errors listed above"
        return 1
    fi
    
    # Check if custom install method
    if [[ "${MODULE_INSTALL_METHOD}" == "custom" ]]; then
        # Source module script and call main_module()
        local module_script="$SCRIPT_DIR/modules/${module_name}.sh"
        if [[ ! -f "$module_script" ]]; then
            log_error "Module script not found: $module_script"
            return 1
        fi
        
        # Save current SCRIPT_DIR and restore it after sourcing (module may overwrite it)
        local saved_script_dir="$SCRIPT_DIR"
        source "$module_script"
        SCRIPT_DIR="$saved_script_dir"  # Restore SCRIPT_DIR in case module overwrote it
        
        if declare -f main_module &>/dev/null; then
            log_info "Running custom installation for $module_name..."
            if main_module; then
                log_success "Module $module_name installed"
                return 0
            else
                log_error "Module $module_name installation failed"
                log_error "Suggestion: Check module logs above for specific errors"
                return 1
            fi
        else
            log_error "main_module() function not found in $module_name"
            log_error "Suggestion: Add main_module() function to modules/${module_name}.sh"
            return 1
        fi
    fi
    
    # Use generic handler based on install method
    case "${MODULE_INSTALL_METHOD}" in
        git_clone)
            install_via_git_clone "$module_name"
            ;;
        pip)
            install_via_pip "$module_name"
            ;;
        package_manager)
            install_via_package_manager "$module_name"
            ;;
        download_script)
            install_via_download_script "$module_name"
            ;;
        *)
            log_error "Unknown install method: ${MODULE_INSTALL_METHOD}"
            return 1
            ;;
    esac
}

# ============================================================================
# Update Handlers
# ============================================================================

# Update module via git pull
update_via_git_pull() {
    local module_name="$1"
    
    if [[ -z "${MODULE_UPDATE_DIR:-}" ]]; then
        log_error "MODULE_UPDATE_DIR not set for module $module_name"
        return 1
    fi
    
    local update_dir="${MODULE_UPDATE_DIR}"
    
    if [[ ! -d "$update_dir" ]]; then
        log_warning "Update directory does not exist: $update_dir"
        return 1
    fi
    
    if [[ ! -d "$update_dir/.git" ]]; then
        log_warning "Not a git repository: $update_dir"
        return 1
    fi
    
    log_info "Updating via git pull in $update_dir..."
    if (cd "$update_dir" && git pull); then
        log_success "Git pull completed"
        return 0
    else
        log_error "Git pull failed"
        return 1
    fi
}

# Update module via pip upgrade
update_via_pip_upgrade() {
    local module_name="$1"
    local package_name="${MODULE_NAME:-$module_name}"
    
    # Detect pip command
    local pip_cmd=""
    if [[ -d "$HOME/.pyenv" ]] && command_exists pip; then
        pip_cmd="pip"
    elif command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        log_error "pip not found"
        return 1
    fi
    
    log_info "Updating $package_name via pip..."
    if $pip_cmd install --upgrade --user "$package_name"; then
        log_success "Updated via pip"
        return 0
    else
        log_error "Failed to update via pip"
        return 1
    fi
}

# Update module via component's own update command
update_via_component_command() {
    local module_name="$1"
    
    # Component-specific update commands
    case "$module_name" in
        bash-it)
            if [[ -d "$HOME/.bash_it" ]] && [[ -f "$HOME/.bash_it/bin/bash-it" ]]; then
                log_info "Running bash-it update..."
                "$HOME/.bash_it/bin/bash-it" update
                return $?
            fi
            ;;
        pyenv)
            if [[ -d "$HOME/.pyenv" ]] && [[ -f "$HOME/.pyenv/bin/pyenv" ]]; then
                log_info "Running pyenv update plugin..."
                "$HOME/.pyenv/bin/pyenv" update
                return $?
            fi
            ;;
        *)
            log_warning "No component command defined for $module_name"
            return 1
            ;;
    esac
    
    return 1
}

# Update module via reinstall
update_via_reinstall() {
    local module_name="$1"
    
    log_info "Reinstalling module $module_name..."
    
    # Temporarily set FORCE_INSTALL
    local old_force="${FORCE_INSTALL:-}"
    export FORCE_INSTALL="true"
    
    # Re-run installation
    if install_module_generic "$module_name"; then
        export FORCE_INSTALL="$old_force"
        log_success "Reinstalled successfully"
        return 0
    else
        export FORCE_INSTALL="$old_force"
        log_error "Reinstallation failed"
        return 1
    fi
}

# Generic module updater
update_module_generic() {
    local module_name="$1"
    
    # Load module metadata
    if ! load_module_metadata "$module_name"; then
        log_error "Cannot update module $module_name: metadata not found"
        return 1
    fi
    
    # Check update method
    if [[ -z "${MODULE_UPDATE_METHOD:-}" ]] || [[ "${MODULE_UPDATE_METHOD}" == "none" ]]; then
        log_info "Module $module_name does not support updates or self-updates"
        return 0
    fi
    
    # Check if custom update method
    if [[ "${MODULE_UPDATE_METHOD}" == "custom" ]]; then
        local module_script="$SCRIPT_DIR/modules/${module_name}.sh"
        if [[ ! -f "$module_script" ]]; then
            log_error "Module script not found: $module_script"
            return 1
        fi
        
        # Save current SCRIPT_DIR and restore it after sourcing (module may overwrite it)
        local saved_script_dir="$SCRIPT_DIR"
        source "$module_script"
        SCRIPT_DIR="$saved_script_dir"  # Restore SCRIPT_DIR in case module overwrote it
        
        if declare -f update_module &>/dev/null; then
            log_info "Running custom update for $module_name..."
            if update_module; then
                log_success "Module $module_name updated"
                return 0
            else
                log_error "Module $module_name update failed"
                return 1
            fi
        else
            log_error "update_module() function not found in $module_name"
            return 1
        fi
    fi
    
    # Use generic handler based on update method
    case "${MODULE_UPDATE_METHOD}" in
        git_pull)
            update_via_git_pull "$module_name"
            ;;
        pip_upgrade)
            update_via_pip_upgrade "$module_name"
            ;;
        component_command)
            update_via_component_command "$module_name"
            ;;
        reinstall)
            update_via_reinstall "$module_name"
            ;;
        *)
            log_error "Unknown update method: ${MODULE_UPDATE_METHOD}"
            return 1
            ;;
    esac
}

# ============================================================================
# Uninstall Handlers
# ============================================================================

# Validate uninstall path for safety
# Checks for dangerous patterns and ensures path is within HOME
validate_uninstall_path() {
    local path="$1"
    
    # Empty string check
    if [[ -z "$path" ]]; then
        log_error "Unsafe path: empty string"
        return 1
    fi
    
    # Check for .. patterns (directory traversal)
    if [[ "$path" =~ \.\. ]]; then
        log_error "Unsafe path (contains '..'): $path"
        return 1
    fi
    
    # No wildcards allowed
    if [[ "$path" =~ [\*\?\[\]] ]]; then
        log_error "Unsafe path (contains wildcards): $path"
        return 1
    fi
    
    # Expand variables
    local expanded_path=$(eval echo "$path")
    
    # Must be within $HOME
    if [[ ! "$expanded_path" =~ ^$HOME ]]; then
        log_error "Unsafe path (outside HOME): $expanded_path"
        return 1
    fi
    
    # Check if expanded path is a symlink pointing outside HOME
    if [[ -L "$expanded_path" ]]; then
        local link_target=$(readlink -f "$expanded_path" 2>/dev/null)
        if [[ -n "$link_target" ]] && [[ ! "$link_target" =~ ^$HOME ]]; then
            log_error "Unsafe path (symlink outside HOME): $expanded_path -> $link_target"
            return 1
        fi
    fi
    
    return 0
}

# Uninstall directories
uninstall_directories() {
    local module_name="$1"
    
    if [[ -z "${MODULE_UNINSTALL_DIRS:-}" ]]; then
        return 0  # Nothing to uninstall
    fi
    
    local dirs=($MODULE_UNINSTALL_DIRS)
    for dir in "${dirs[@]}"; do
        if ! validate_uninstall_path "$dir"; then
            log_warning "Skipping unsafe path: $dir"
            continue
        fi
        
        local expanded_dir=$(eval echo "$dir")
        if [[ -d "$expanded_dir" ]]; then
            log_info "Removing directory: $expanded_dir"
            rm -rf "$expanded_dir"
            if [[ $? -eq 0 ]]; then
                log_success "Removed: $expanded_dir"
            else
                log_warning "Failed to remove: $expanded_dir"
            fi
        else
            log_info "Directory does not exist: $expanded_dir"
        fi
    done
    
    return 0
}

# Uninstall files
uninstall_files() {
    local module_name="$1"
    
    if [[ -z "${MODULE_UNINSTALL_FILES:-}" ]]; then
        return 0  # Nothing to uninstall
    fi
    
    local files=($MODULE_UNINSTALL_FILES)
    for file in "${files[@]}"; do
        if ! validate_uninstall_path "$file"; then
            log_warning "Skipping unsafe path: $file"
            continue
        fi
        
        local expanded_file=$(eval echo "$file")
        if [[ -f "$expanded_file" ]]; then
            log_info "Removing file: $expanded_file"
            rm -f "$expanded_file"
            if [[ $? -eq 0 ]]; then
                log_success "Removed: $expanded_file"
            else
                log_warning "Failed to remove: $expanded_file"
            fi
        fi
    done
    
    return 0
}

# Uninstall binaries
uninstall_binaries() {
    local module_name="$1"
    
    if [[ -z "${MODULE_UNINSTALL_BINARIES:-}" ]]; then
        return 0  # Nothing to uninstall
    fi
    
    local binaries=($MODULE_UNINSTALL_BINARIES)
    for binary in "${binaries[@]}"; do
        local bin_path="$HOME/.local/bin/$binary"
        if [[ -f "$bin_path" ]]; then
            log_info "Removing binary: $bin_path"
            rm -f "$bin_path"
        fi
    done
    
    return 0
}

# Uninstall pip packages
uninstall_pip_packages() {
    local module_name="$1"
    
    if [[ -z "${MODULE_UNINSTALL_PIP_PACKAGES:-}" ]]; then
        return 0  # Nothing to uninstall
    fi
    
    # Detect pip command
    local pip_cmd=""
    if [[ -d "$HOME/.pyenv" ]] && command_exists pip; then
        pip_cmd="pip"
    elif command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        log_warning "pip not found, skipping pip package uninstall"
        return 0
    fi
    
    local packages=($MODULE_UNINSTALL_PIP_PACKAGES)
    for package in "${packages[@]}"; do
        log_info "Uninstalling pip package: $package"
        if $pip_cmd uninstall -y "$package" &>/dev/null; then
            log_success "Uninstalled: $package"
        else
            log_warning "Failed to uninstall or not installed: $package"
        fi
    done
    
    return 0
}

# Generic module uninstaller
uninstall_module_generic() {
    local module_name="$1"
    
    # Load module metadata
    if ! load_module_metadata "$module_name"; then
        log_error "Cannot uninstall module $module_name: metadata not found"
        return 1
    fi
    
    # Check if custom uninstall method
    local module_script="$SCRIPT_DIR/modules/${module_name}.sh"
    if [[ -f "$module_script" ]]; then
        # Save current SCRIPT_DIR and restore it after sourcing (module may overwrite it)
        local saved_script_dir="$SCRIPT_DIR"
        source "$module_script"
        SCRIPT_DIR="$saved_script_dir"  # Restore SCRIPT_DIR in case module overwrote it
        
        if declare -f uninstall_module &>/dev/null; then
            log_info "Running custom uninstall for $module_name..."
            if uninstall_module; then
                log_success "Module $module_name uninstalled"
                return 0
            else
                log_error "Module $module_name uninstall failed"
                return 1
            fi
        fi
    fi
    
    # Use generic handlers
    uninstall_directories "$module_name"
    uninstall_files "$module_name"
    uninstall_binaries "$module_name"
    uninstall_pip_packages "$module_name"
    
    log_success "Module $module_name uninstalled"
    return 0
}

# ============================================================================
# Test Handlers
# ============================================================================

# Test module command
test_module_command() {
    local module_name="$1"
    
    if [[ -z "${MODULE_TEST_COMMAND:-}" ]]; then
        return 0  # No command to test
    fi
    
    if eval "${MODULE_TEST_COMMAND}"; then
        log_success "Test command passed"
        return 0
    else
        log_warning "Test command failed"
        return 1
    fi
}

# Test module directories
test_module_directories() {
    local module_name="$1"
    
    if [[ -z "${MODULE_TEST_DIRS:-}" ]]; then
        return 0  # Nothing to test
    fi
    
    local dirs=($MODULE_TEST_DIRS)
    local failed=0
    
    for dir in "${dirs[@]}"; do
        local expanded_dir=$(eval echo "$dir")
        if [[ -d "$expanded_dir" ]]; then
            log_success "Directory exists: $expanded_dir"
        else
            log_warning "Directory missing: $expanded_dir"
            failed=1
        fi
    done
    
    return $failed
}

# Test module files
test_module_files() {
    local module_name="$1"
    
    if [[ -z "${MODULE_TEST_FILES:-}" ]]; then
        return 0  # Nothing to test
    fi
    
    local files=($MODULE_TEST_FILES)
    local failed=0
    
    for file in "${files[@]}"; do
        local expanded_file=$(eval echo "$file")
        if [[ -f "$expanded_file" ]]; then
            log_success "File exists: $expanded_file"
        else
            log_warning "File missing: $expanded_file"
            failed=1
        fi
    done
    
    return $failed
}

# Test module binaries
test_module_binaries() {
    local module_name="$1"
    
    if [[ -z "${MODULE_TEST_BINARIES:-}" ]]; then
        return 0  # Nothing to test
    fi
    
    local binaries=($MODULE_TEST_BINARIES)
    local failed=0
    
    for binary in "${binaries[@]}"; do
        if command_exists "$binary"; then
            log_success "Binary found: $binary"
        else
            log_warning "Binary missing: $binary"
            failed=1
        fi
    done
    
    return $failed
}

# Generic module tester
test_module_generic() {
    local module_name="$1"
    
    # Load module metadata
    if ! load_module_metadata "$module_name"; then
        log_error "Cannot test module $module_name: metadata not found"
        return 1
    fi
    
    # Check if custom test function exists
    local module_script="$SCRIPT_DIR/modules/${module_name}.sh"
    if [[ -f "$module_script" ]]; then
        # Save current SCRIPT_DIR and restore it after sourcing (module may overwrite it)
        local saved_script_dir="$SCRIPT_DIR"
        source "$module_script"
        SCRIPT_DIR="$saved_script_dir"  # Restore SCRIPT_DIR in case module overwrote it
        
        if declare -f check_module_installed &>/dev/null; then
            log_info "Running custom test for $module_name..."
            if check_module_installed; then
                log_success "Module $module_name is installed"
                return 0
            else
                log_warning "Module $module_name is not installed"
                return 1
            fi
        fi
    fi
    
    # Use generic tests
    local failed=0
    
    test_module_command "$module_name" || failed=1
    test_module_directories "$module_name" || failed=1
    test_module_files "$module_name" || failed=1
    test_module_binaries "$module_name" || failed=1
    
    if [[ $failed -eq 0 ]]; then
        log_success "All tests passed for $module_name"
        return 0
    else
        log_warning "Some tests failed for $module_name"
        return 1
    fi
}

