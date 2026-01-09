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
    unset MODULE_OPTIONAL MODULE_CORE MODULE_CONFIG
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
# Installation Logic
# ============================================================================

# Check if module is installed
check_installed() {
    local name="$1"
    
    load_module "$name" || return 1
    
    # Custom is_installed function takes priority
    if declare -f is_installed &>/dev/null; then
        is_installed
        return $?
    fi
    
    # Check binary if specified
    if [[ -n "${MODULE_BIN:-}" ]]; then
        command_exists "$MODULE_BIN"
        return $?
    fi
    
    # Check directory if specified
    if [[ -n "${MODULE_DIR:-}" ]]; then
        [[ -d "$MODULE_DIR" ]]
        return $?
    fi
    
    return 1
}

# Install a module
install_module() {
    local name="$1"
    
    load_module "$name" || { log_error "Module not found: $name"; return 1; }
    
    # Skip if already installed (unless forcing)
    if [[ "${FORCE_INSTALL:-}" != "true" ]] && check_installed "$name"; then
        log_info "$name is already installed"
        return 0
    fi
    
    # Remove existing if forcing
    if [[ "${FORCE_INSTALL:-}" == "true" ]] && [[ -n "${MODULE_DIR:-}" ]] && [[ -d "$MODULE_DIR" ]]; then
        log_info "Removing existing $name installation..."
        rm -rf "$MODULE_DIR"
    fi
    
    log_info "Installing $name..."
    
    # Custom install function takes priority
    if declare -f install &>/dev/null; then
        if install; then
            log_success "$name installed"
            return 0
        else
            log_error "$name installation failed"
            return 1
        fi
    fi
    
    # Default: git clone if repo specified
    if [[ -n "${MODULE_REPO:-}" ]] && [[ -n "${MODULE_DIR:-}" ]]; then
        if git clone --depth=1 "$MODULE_REPO" "$MODULE_DIR"; then
            # Run post_install if defined
            if declare -f post_install &>/dev/null; then
                post_install || log_warning "post_install hook had issues"
            fi
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
            log_success "$name installed"
            return 0
        else
            log_error "Failed to run install script"
            return 1
        fi
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
