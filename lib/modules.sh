#!/usr/bin/env bash
# Simplified Module System for Slaane.sh
# Convention over configuration - modules are declarative with optional hooks

# ============================================================================
# Module Discovery
# ============================================================================

# Discover all modules in modules/ directory
discover_modules() {
    local modules_dir="$SCRIPT_DIR/modules"
    local modules=()
    
    for file in "$modules_dir"/*.sh; do
        [[ -f "$file" ]] || continue
        modules+=("$(basename "$file" .sh)")
    done
    
    printf '%s\n' "${modules[@]}" | sort
}

# ============================================================================
# Module Loading & Metadata
# ============================================================================

# Clear module variables before loading new module
clear_module_vars() {
    unset MODULE_DIR MODULE_REPO MODULE_BIN MODULE_SCRIPT
    unset MODULE_OPTIONAL MODULE_CORE MODULE_CONFIG MODULE_INTERACTIVE MODULE_MANUAL
    unset MODULE_PKG_NAME MODULE_PIP MODULE_CHECK_FILE MODULE_NOTE
    # v0.3.0 additions
    unset MODULE_GITHUB MODULE_GITHUB_BINARY MODULE_PIPX MODULE_PROJECT_URL
    unset MODULE_REQUIRES MODULE_REPLACES
    unset MODULE_BASHIT_PLUGIN MODULE_BASHIT_ALIASES
    unset -f install post_install update uninstall is_installed
}

# Load a module file and extract its configuration
load_module() {
    local name="$1"
    local module_file="$SCRIPT_DIR/modules/${name}.sh"
    
    [[ -f "$module_file" ]] || return 1
    
    clear_module_vars
    source "$module_file"
}

# Get module description from comment on line 2
get_module_desc() {
    local name="$1"
    local module_file="$SCRIPT_DIR/modules/${name}.sh"
    
    sed -n '2s/^# *//p' "$module_file" 2>/dev/null || echo "No description"
}

# ============================================================================
# Pre-Install Checks
# ============================================================================

# Check if tool already exists in PATH
# Used to skip installation if tool is already available
tool_exists() {
    local bin="${MODULE_BIN:-}"
    [[ -z "$bin" ]] && return 1
    command -v "$bin" &>/dev/null
}

# Check if module dependencies are satisfied
# Modules declare dependencies via MODULE_REQUIRES
check_requires() {
    local name="$1"
    [[ -z "${MODULE_REQUIRES:-}" ]] && return 0
    
    for req in $MODULE_REQUIRES; do
        if ! check_installed "$req"; then
            log_error "$name requires $req - install it first"
            return 1
        fi
    done
    return 0
}

# ============================================================================
# Post-Install Handlers
# ============================================================================

# Handle drop-in replacement aliases
# Creates aliases for tools that replace standard commands (e.g., bat -> cat)
handle_alias() {
    local name="$1"
    [[ -z "${MODULE_REPLACES:-}" ]] && return 0
    [[ -z "${MODULE_BIN:-}" ]] && return 0
    
    local alias_file="$HOME/.slaane.sh/aliases.sh"
    mkdir -p "$(dirname "$alias_file")"
    
    # Add alias if not already present
    local alias_line="alias ${MODULE_REPLACES}='${MODULE_BIN}'"
    if ! grep -qF "$alias_line" "$alias_file" 2>/dev/null; then
        echo "$alias_line" >> "$alias_file"
        log_info "Created alias: ${MODULE_REPLACES} → ${MODULE_BIN}"
    fi
}

# Remove alias on uninstall
remove_alias() {
    local alias_file="$HOME/.slaane.sh/aliases.sh"
    [[ -z "${MODULE_REPLACES:-}" ]] && return 0
    [[ -f "$alias_file" ]] || return 0
    
    # Remove the alias line
    sed -i "/alias ${MODULE_REPLACES}=/d" "$alias_file"
}

# Handle bash-it plugin and alias integration
# Automatically enables bash-it plugins/aliases when module is installed
handle_bashit() {
    local name="$1"
    
    # Skip if bash-it is not installed
    [[ -d "$HOME/.bash_it" ]] || return 0
    
    # Enable plugin if specified
    if [[ -n "${MODULE_BASHIT_PLUGIN:-}" ]]; then
        if [[ -f "$HOME/.bash_it/plugins/available/${MODULE_BASHIT_PLUGIN}.plugin.bash" ]]; then
            bash-it enable plugin "$MODULE_BASHIT_PLUGIN" 2>/dev/null || true
            log_info "Enabled bash-it plugin: $MODULE_BASHIT_PLUGIN"
        fi
    fi
    
    # Enable aliases if specified
    if [[ -n "${MODULE_BASHIT_ALIASES:-}" ]]; then
        if [[ -f "$HOME/.bash_it/aliases/available/${MODULE_BASHIT_ALIASES}.aliases.bash" ]]; then
            bash-it enable alias "$MODULE_BASHIT_ALIASES" 2>/dev/null || true
            log_info "Enabled bash-it aliases: $MODULE_BASHIT_ALIASES"
        fi
    fi
}

# ============================================================================
# Installation Helpers
# ============================================================================

# Install package via system package manager
install_system_package() {
    local pkg="$1"
    
    # Check if already installed
    if command_exists "$pkg" 2>/dev/null; then
        return 0
    fi
    
    # Need sudo
    if ! prompt_for_sudo "install $pkg"; then
        return 1
    fi
    
    RUN_AS_ROOT_OPERATION="install $pkg" run_as_root $PKG_INSTALL "$pkg"
}

# Install package via pip
install_pip_package() {
    local pkg="$1"
    local pip_cmd=""
    
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        log_error "pip not found"
        return 1
    fi
    
    $pip_cmd install --user "$pkg"
}

# Update pip package
update_pip_package() {
    local pkg="$1"
    local pip_cmd=""
    
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        return 1
    fi
    
    $pip_cmd install --user --upgrade "$pkg"
}

# Uninstall pip package
uninstall_pip_package() {
    local pkg="$1"
    local pip_cmd=""
    
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        return 1
    fi
    
    $pip_cmd uninstall -y "$pkg"
}

# ============================================================================
# Installation Logic
# ============================================================================

# Check if module is installed
# Uses AND logic - all defined checks must pass
check_installed() {
    local name="$1"
    
    load_module "$name" || return 1
    
    # Custom is_installed function takes priority
    if declare -f is_installed &>/dev/null; then
        is_installed
        return $?
    fi
    
    # AND all defined checks together
    if [[ -n "${MODULE_BIN:-}" ]] && ! command_exists "$MODULE_BIN"; then
        return 1
    fi
    
    if [[ -n "${MODULE_DIR:-}" ]] && [[ ! -d "$MODULE_DIR" ]]; then
        return 1
    fi
    
    if [[ -n "${MODULE_CHECK_FILE:-}" ]] && [[ ! -f "$MODULE_CHECK_FILE" ]]; then
        return 1
    fi
    
    # At least one check must be defined
    [[ -n "${MODULE_BIN:-}" ]] || [[ -n "${MODULE_DIR:-}" ]] || [[ -n "${MODULE_CHECK_FILE:-}" ]]
}

# Install a module
install_module() {
    local name="$1"
    
    load_module "$name" || { log_error "Module not found: $name"; return 1; }
    
    # Check dependencies first
    if ! check_requires "$name"; then
        return 1
    fi
    
    # Pre-check: Tool already exists in PATH?
    if tool_exists; then
        if [[ "${FORCE_LOCAL:-}" != "true" ]]; then
            log_info "$name already installed at $(command -v "$MODULE_BIN")"
            # Still run post_install for config setup
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            # Handle aliases and bash-it integration even for existing tools
            handle_alias "$name"
            handle_bashit "$name"
            return 0
        else
            log_info "$name exists but --force-local specified, installing local version..."
        fi
    fi
    
    # Skip if already installed via our methods (unless forcing)
    if [[ "${FORCE_INSTALL:-}" != "true" ]] && [[ "${FORCE_LOCAL:-}" != "true" ]] && check_installed "$name"; then
        log_info "$name is already installed"
        return 0
    fi
    
    # Remove existing if forcing
    if [[ "${FORCE_INSTALL:-}" == "true" ]] && [[ -n "${MODULE_DIR:-}" ]] && [[ -d "$MODULE_DIR" ]]; then
        log_info "Removing existing $name installation..."
        rm -rf "$MODULE_DIR"
    fi
    
    log_info "Installing $name..."
    
    # Print module note if defined
    if [[ -n "${MODULE_NOTE:-}" ]]; then
        log_warning "$MODULE_NOTE"
    fi
    
    # Custom install function takes priority
    if declare -f install &>/dev/null; then
        if install; then
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            handle_alias "$name"
            handle_bashit "$name"
            log_success "$name installed"
            return 0
        else
            log_error "$name installation failed"
            return 1
        fi
    fi
    
    # =========================================================================
    # Install Cascade (v0.3.0)
    # =========================================================================
    
    # Option 1: System package (if --global or PREFER_GLOBAL)
    if [[ "${PREFER_GLOBAL:-}" == "true" ]] && [[ -n "${MODULE_PKG_NAME:-}" ]]; then
        if install_system_package "${MODULE_PKG_NAME}"; then
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            handle_alias "$name"
            handle_bashit "$name"
            log_success "$name installed via system package"
            return 0
        else
            log_warning "System package install failed, trying user-space methods..."
        fi
    fi
    
    # Option 2: GitHub binary via dra (if MODULE_GITHUB set)
    if [[ -n "${MODULE_GITHUB:-}" ]]; then
        if install_github_binary "${MODULE_GITHUB}"; then
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            handle_alias "$name"
            handle_bashit "$name"
            log_success "$name installed via dra"
            return 0
        else
            log_warning "GitHub binary install failed"
        fi
    fi
    
    # Option 3: pipx install (if MODULE_PIPX set)
    if [[ -n "${MODULE_PIPX:-}" ]]; then
        if try_pipx_install "${MODULE_PIPX}"; then
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            handle_alias "$name"
            handle_bashit "$name"
            log_success "$name installed via pipx"
            return 0
        else
            log_error "Failed to install ${MODULE_PIPX} via pipx"
            return 1
        fi
    fi
    
    # =========================================================================
    # Legacy install methods (for existing modules)
    # =========================================================================
    
    # Install system package if specified (legacy path - no PREFER_GLOBAL check)
    if [[ -n "${MODULE_PKG_NAME:-}" ]]; then
        if install_system_package "${MODULE_PKG_NAME}"; then
            # Continue to other install methods (e.g., nano needs pkg + git clone)
            :
        else
            log_warning "Package ${MODULE_PKG_NAME} not installed"
        fi
    fi
    
    # Install pip package if specified (legacy - use MODULE_PIPX for new modules)
    if [[ -n "${MODULE_PIP:-}" ]]; then
        if install_pip_package "${MODULE_PIP}"; then
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            handle_alias "$name"
            handle_bashit "$name"
            log_success "$name installed"
            return 0
        else
            log_error "Failed to install ${MODULE_PIP} via pip"
            return 1
        fi
    fi
    
    # Git clone if repo specified
    if [[ -n "${MODULE_REPO:-}" ]] && [[ -n "${MODULE_DIR:-}" ]]; then
        if git clone --depth=1 "$MODULE_REPO" "$MODULE_DIR"; then
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            handle_alias "$name"
            handle_bashit "$name"
            log_success "$name installed"
            return 0
        else
            log_error "Failed to clone $MODULE_REPO"
            return 1
        fi
    fi
    
    # Download script if specified
    if [[ -n "${MODULE_SCRIPT:-}" ]]; then
        if curl -fsSL "$MODULE_SCRIPT" | bash; then
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            handle_alias "$name"
            handle_bashit "$name"
            log_success "$name installed"
            return 0
        else
            log_error "Failed to run install script"
            return 1
        fi
    fi
    
    # If we have a PROJECT_URL, show it in the error message
    if [[ -n "${MODULE_PROJECT_URL:-}" ]]; then
        log_error "No install method succeeded for $name"
        log_info "Manual install: ${MODULE_PROJECT_URL}"
        return 1
    fi
    
    log_error "No install method defined for $name"
    return 1
}

# Update a module
update_module() {
    local name="$1"
    
    load_module "$name" || { log_error "Module not found: $name"; return 1; }
    
    if ! check_installed "$name"; then
        log_warning "$name is not installed"
        return 1
    fi
    
    log_info "Updating $name..."
    
    # Custom update function takes priority
    if declare -f update &>/dev/null; then
        if update; then
            log_success "$name updated"
            return 0
        else
            log_error "$name update failed"
            return 1
        fi
    fi
    
    # Update via pipx if MODULE_PIPX is set
    if [[ -n "${MODULE_PIPX:-}" ]]; then
        if upgrade_pipx_package "${MODULE_PIPX}"; then
            log_success "$name updated via pipx"
            return 0
        else
            log_error "$name pipx update failed"
            return 1
        fi
    fi
    
    # Update GitHub binary via dra (re-download latest)
    if [[ -n "${MODULE_GITHUB:-}" ]]; then
        if install_github_binary "${MODULE_GITHUB}"; then
            log_success "$name updated via dra"
            return 0
        else
            log_error "$name dra update failed"
            return 1
        fi
    fi
    
    # Update pip package if specified (legacy)
    if [[ -n "${MODULE_PIP:-}" ]]; then
        if update_pip_package "${MODULE_PIP}"; then
            log_success "$name updated"
            return 0
        else
            log_error "$name update failed"
            return 1
        fi
    fi
    
    # Default: git pull if directory exists and is a git repo
    if [[ -n "${MODULE_DIR:-}" ]] && [[ -d "$MODULE_DIR/.git" ]]; then
        if (cd "$MODULE_DIR" && git pull); then
            # Run post_install if defined (for rebuild steps)
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
            log_success "$name updated"
            return 0
        else
            log_error "git pull failed"
            return 1
        fi
    fi
    
    log_info "$name doesn't support updates"
    return 0
}

# Uninstall a module
uninstall_module() {
    local name="$1"
    
    load_module "$name" || { log_error "Module not found: $name"; return 1; }
    
    log_info "Uninstalling $name..."
    
    # Remove alias if this module creates one
    remove_alias
    
    # Custom uninstall function takes priority
    if declare -f uninstall &>/dev/null; then
        if uninstall; then
            log_success "$name uninstalled"
            return 0
        else
            log_error "$name uninstall failed"
            return 1
        fi
    fi
    
    # Uninstall binary from ~/.local/bin (GitHub/dra installs)
    if [[ -n "${MODULE_BIN:-}" ]]; then
        local bin_path="$HOME/.local/bin/${MODULE_BIN}"
        if [[ -f "$bin_path" ]]; then
            rm -f "$bin_path"
            log_success "$name uninstalled (removed $bin_path)"
            return 0
        fi
    fi
    
    # Uninstall pipx package if specified
    if [[ -n "${MODULE_PIPX:-}" ]]; then
        if uninstall_pipx_package "${MODULE_PIPX}"; then
            log_success "$name uninstalled"
            return 0
        else
            log_error "$name uninstall failed"
            return 1
        fi
    fi
    
    # Uninstall pip package if specified (legacy)
    if [[ -n "${MODULE_PIP:-}" ]]; then
        if uninstall_pip_package "${MODULE_PIP}"; then
            log_success "$name uninstalled"
            return 0
        else
            log_error "$name uninstall failed"
            return 1
        fi
    fi
    
    # Default: remove directory
    if [[ -n "${MODULE_DIR:-}" ]] && [[ -d "$MODULE_DIR" ]]; then
        rm -rf "$MODULE_DIR"
        log_success "$name uninstalled"
        return 0
    fi
    
    log_warning "No uninstall method for $name"
    return 0
}

# ============================================================================
# Module Classification
# ============================================================================

# Check if module is core (always installed, failure is fatal)
is_core_module() {
    local name="$1"
    load_module "$name" || return 1
    [[ "${MODULE_CORE:-false}" == "true" ]]
}

# Check if module is optional (requires explicit flag)
is_optional_module() {
    local name="$1"
    load_module "$name" || return 1
    [[ "${MODULE_OPTIONAL:-false}" == "true" ]]
}

# Get list of modules by type
get_core_modules() {
    for mod in $(discover_modules); do
        is_core_module "$mod" && echo "$mod"
    done
}

get_default_modules() {
    for mod in $(discover_modules); do
        is_core_module "$mod" && continue
        is_optional_module "$mod" && continue
        echo "$mod"
    done
}

get_optional_modules() {
    for mod in $(discover_modules); do
        is_optional_module "$mod" && echo "$mod"
    done
}
