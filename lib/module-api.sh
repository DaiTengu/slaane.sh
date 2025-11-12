#!/usr/bin/env bash
# Module API - Discovery, metadata loading, validation, and dependency resolution

# Ensure SCRIPT_DIR is set (this should be set by the caller)
# If not set, assume we're in lib/ directory
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
if ! declare -f log_info &>/dev/null; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

# Bootstrap module environment
# This function should be called at the start of each module script
# It sets up SCRIPT_DIR and sources required libraries
bootstrap_module() {
    # Set SCRIPT_DIR if not already set (when module is run directly)
    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
    
    # Source common functions if not already loaded
    if ! declare -f log_info &>/dev/null; then
        source "$SCRIPT_DIR/lib/common.sh"
    fi
    
    # Source module handlers if not already loaded
    if ! declare -f install_module_generic &>/dev/null; then
        source "$SCRIPT_DIR/lib/module-handlers.sh"
    fi
}

# Discover all modules in modules/ directory
# Returns list of module names (without .sh extension)
discover_modules() {
    local modules_dir="${SCRIPT_DIR}/modules"
    local modules=()
    
    if [[ ! -d "$modules_dir" ]]; then
        log_error "Modules directory not found: $modules_dir"
        log_error "Please ensure you're running from the slaane.sh repository root"
        return 1
    fi
    
    if [[ ! -r "$modules_dir" ]]; then
        log_error "Modules directory is not readable: $modules_dir"
        return 1
    fi
    
    # Find all .sh files in modules directory
    # Use a more portable approach that works on older bash versions
    local file
    local found_any=false
    for file in "$modules_dir"/*.sh; do
        # Check if file exists (glob might not match)
        if [[ -f "$file" ]]; then
            found_any=true
            local basename=$(basename "$file" .sh)
            modules+=("$basename")
        fi
    done
    
    if [[ "$found_any" == false ]]; then
        log_warning "No module files found in $modules_dir"
        return 1
    fi
    
    # Sort modules alphabetically
    if [[ ${#modules[@]} -gt 0 ]]; then
        IFS=$'\n' modules=($(printf '%s\n' "${modules[@]}" | sort))
        unset IFS
    fi
    
    echo "${modules[@]}"
}

# Extract embedded metadata from script file
extract_embedded_metadata() {
    local script_file="$1"
    local in_metadata=false
    local temp_file=$(mktemp)
    
    if [[ ! -f "$script_file" ]]; then
        log_error "Script file not found: $script_file"
        return 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check for metadata start marker
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*Metadata:[[:space:]]*START[[:space:]]*$ ]]; then
            in_metadata=true
            continue
        fi
        
        # Check for metadata end marker
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*Metadata:[[:space:]]*END[[:space:]]*$ ]]; then
            break
        fi
        
        # Extract metadata lines
        if [[ "$in_metadata" == true ]]; then
            # Remove leading # and whitespace, keep the rest
            local clean_line="${line#\#}"
            clean_line="${clean_line#"${clean_line%%[![:space:]]*}"}"  # trim leading space
            
            # Only process lines that look like variable assignments
            if [[ "$clean_line" =~ ^MODULE_ ]]; then
                echo "$clean_line" >> "$temp_file"
            fi
        fi
    done < "$script_file"
    
    # Source the extracted metadata
    if [[ -s "$temp_file" ]]; then
        source "$temp_file"
        rm -f "$temp_file"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Load module metadata from .conf file or embedded in script
# Note: Metadata is loaded fresh each time to ensure consistency
# Future optimization: Could cache metadata with file mtime checks
load_module_metadata() {
    local module_name="$1"
    local conf_file="$SCRIPT_DIR/modules/${module_name}.conf"
    local script_file="$SCRIPT_DIR/modules/${module_name}.sh"
    
    # Clear any existing module metadata variables
    unset MODULE_NAME MODULE_DESCRIPTION MODULE_ENABLED_BY_DEFAULT MODULE_IS_CORE
    unset MODULE_DEPENDS MODULE_INSTALL_METHOD MODULE_INSTALL_DIRS MODULE_INSTALL_REPO
    unset MODULE_INSTALL_ARGS MODULE_UPDATE_METHOD MODULE_UPDATE_DIR MODULE_UNINSTALL_DIRS
    unset MODULE_CONFIG_FILES MODULE_TEST_DIRS MODULE_TEST_FILES MODULE_TEST_BINARIES MODULE_TEST_COMMAND
    
    # Priority 1: Separate .conf file (if exists)
    if [[ -f "$conf_file" ]]; then
        source "$conf_file"
        return 0
    fi
    
    # Priority 2: Extract embedded metadata from script
    if [[ -f "$script_file" ]]; then
        if extract_embedded_metadata "$script_file"; then
            return 0
        fi
    fi
    
    # No metadata found
    log_warning "No metadata found for module: $module_name"
    return 1
}

# Validate module metadata
# Ensures all required fields are present and valid
validate_module_metadata() {
    local module_name="$1"
    local errors=0
    
    # Required fields
    if [[ -z "${MODULE_NAME:-}" ]]; then
        log_error "Module $module_name: MODULE_NAME is required"
        ((errors++))
    fi
    
    if [[ -z "${MODULE_DESCRIPTION:-}" ]]; then
        log_error "Module $module_name: MODULE_DESCRIPTION is required"
        ((errors++))
    fi
    
    if [[ -z "${MODULE_ENABLED_BY_DEFAULT:-}" ]]; then
        log_error "Module $module_name: MODULE_ENABLED_BY_DEFAULT is required"
        ((errors++))
    fi
    
    if [[ -z "${MODULE_IS_CORE:-}" ]]; then
        log_error "Module $module_name: MODULE_IS_CORE is required"
        ((errors++))
    fi
    
    if [[ -z "${MODULE_INSTALL_METHOD:-}" ]]; then
        log_error "Module $module_name: MODULE_INSTALL_METHOD is required"
        ((errors++))
    fi
    
    # Validate boolean fields
    if [[ -n "${MODULE_ENABLED_BY_DEFAULT:-}" ]] && \
       [[ "${MODULE_ENABLED_BY_DEFAULT}" != "true" ]] && \
       [[ "${MODULE_ENABLED_BY_DEFAULT}" != "false" ]]; then
        log_error "Module $module_name: MODULE_ENABLED_BY_DEFAULT must be 'true' or 'false', got '${MODULE_ENABLED_BY_DEFAULT}'"
        ((errors++))
    fi
    
    if [[ -n "${MODULE_IS_CORE:-}" ]] && \
       [[ "${MODULE_IS_CORE}" != "true" ]] && \
       [[ "${MODULE_IS_CORE}" != "false" ]]; then
        log_error "Module $module_name: MODULE_IS_CORE must be 'true' or 'false', got '${MODULE_IS_CORE}'"
        ((errors++))
    fi
    
    # Validate MODULE_NAME matches filename (if MODULE_NAME is set)
    if [[ -n "${MODULE_NAME:-}" ]] && [[ "$MODULE_NAME" != "$module_name" ]]; then
        log_error "Module $module_name: MODULE_NAME mismatch (expected '$module_name', got '$MODULE_NAME')"
        ((errors++))
    fi
    
    # Validate install method
    if [[ -n "${MODULE_INSTALL_METHOD:-}" ]]; then
        local valid_methods="git_clone pip package_manager download_script custom"
        if [[ ! " $valid_methods " =~ " ${MODULE_INSTALL_METHOD} " ]]; then
            log_error "Module $module_name: Invalid MODULE_INSTALL_METHOD: $MODULE_INSTALL_METHOD (valid: $valid_methods)"
            ((errors++))
        fi
        
        # Validate install method requirements
        case "${MODULE_INSTALL_METHOD}" in
            git_clone)
                if [[ -z "${MODULE_INSTALL_REPO:-}" ]]; then
                    log_error "Module $module_name: MODULE_INSTALL_REPO required for git_clone method"
                    ((errors++))
                fi
                if [[ -z "${MODULE_INSTALL_DIRS:-}" ]]; then
                    log_error "Module $module_name: MODULE_INSTALL_DIRS required for git_clone method"
                    ((errors++))
                fi
                ;;
            download_script)
                if [[ -z "${MODULE_INSTALL_REPO:-}" ]]; then
                    log_error "Module $module_name: MODULE_INSTALL_REPO (script URL) required for download_script method"
                    ((errors++))
                fi
                ;;
        esac
    fi
    
    # Validate update method (if specified)
    if [[ -n "${MODULE_UPDATE_METHOD:-}" ]]; then
        local valid_update_methods="git_pull pip_upgrade component_command reinstall custom none"
        if [[ ! " $valid_update_methods " =~ " ${MODULE_UPDATE_METHOD} " ]]; then
            log_error "Module $module_name: Invalid MODULE_UPDATE_METHOD: $MODULE_UPDATE_METHOD (valid: $valid_update_methods)"
            ((errors++))
        fi
        
        # Validate update method requirements
        if [[ "${MODULE_UPDATE_METHOD}" == "git_pull" ]] && [[ -z "${MODULE_UPDATE_DIR:-}" ]]; then
            log_error "Module $module_name: MODULE_UPDATE_DIR required for git_pull update method"
            ((errors++))
        fi
    fi
    
    # Warn about missing uninstall directories (non-fatal)
    if [[ -z "${MODULE_UNINSTALL_DIRS:-}" ]] && \
       [[ -z "${MODULE_UNINSTALL_FILES:-}" ]] && \
       [[ -z "${MODULE_UNINSTALL_BINARIES:-}" ]] && \
       [[ -z "${MODULE_UNINSTALL_PIP_PACKAGES:-}" ]]; then
        log_warning "Module $module_name: No uninstall targets specified (nothing will be uninstalled)"
    fi
    
    return $((errors > 0 ? 1 : 0))
}

# Validate module has required functions
validate_module_functions() {
    local module_name="$1"
    local script_file="$SCRIPT_DIR/modules/${module_name}.sh"
    
    if [[ ! -f "$script_file" ]]; then
        log_error "Module script not found: $script_file"
        return 1
    fi
    
    # Check for required function using grep (avoid sourcing to prevent execution)
    if ! grep -q "^main_module()" "$script_file"; then
        log_error "Module $module_name: main_module() function not found"
        return 1
    fi
    
    return 0
}

# Validate module (metadata + functions)
validate_module() {
    local module_name="$1"
    
    if ! load_module_metadata "$module_name"; then
        return 1
    fi
    
    if ! validate_module_metadata "$module_name"; then
        return 1
    fi
    
    if ! validate_module_functions "$module_name"; then
        return 1
    fi
    
    return 0
}

# Resolve module dependencies
resolve_dependencies() {
    local module_name="$1"
    local resolved=()
    local visited=()
    
    _resolve_deps_recursive "$module_name" resolved visited
}

# Recursive dependency resolution with cycle detection
_resolve_deps_recursive() {
    local module_name="$1"
    local -n resolved_ref="$2"
    local -n visited_ref="$3"
    
    # Check for circular dependencies
    if [[ " ${visited_ref[@]} " =~ " ${module_name} " ]]; then
        log_error "Circular dependency detected involving: $module_name"
        return 1
    fi
    
    visited_ref+=("$module_name")
    
    # Load module metadata
    if ! load_module_metadata "$module_name"; then
        log_error "Cannot resolve dependencies for $module_name: metadata not found"
        return 1
    fi
    
    # If already resolved, skip
    if [[ " ${resolved_ref[@]} " =~ " ${module_name} " ]]; then
        return 0
    fi
    
    # Resolve dependencies
    if [[ -n "${MODULE_DEPENDS:-}" ]]; then
        local deps=($MODULE_DEPENDS)
        for dep in "${deps[@]}"; do
            # Check if dependency module exists
            if [[ ! -f "$SCRIPT_DIR/modules/${dep}.sh" ]]; then
                log_error "Module $module_name: Dependency '$dep' not found"
                return 1
            fi
            
            # Recursively resolve dependency
            if ! _resolve_deps_recursive "$dep" resolved_ref visited_ref; then
                return 1
            fi
        done
    fi
    
    # Add to resolved list
    resolved_ref+=("$module_name")
    return 0
}

# Get module enabled status (CLI flags > metadata)
# NOTE: This function is currently unused but kept for potential future use
# Module enablement is currently handled directly in slaane.sh cmd_install()
get_module_enabled_status() {
    local module_name="$1"
    
    # Check if explicitly skipped via CLI
    if check_module_should_skip "$module_name"; then
        return 1  # Disabled
    fi
    
    # Load metadata
    if ! load_module_metadata "$module_name"; then
        return 1  # Can't determine, assume disabled
    fi
    
    # Check metadata
    if [[ "${MODULE_ENABLED_BY_DEFAULT:-false}" == "true" ]]; then
        return 0  # Enabled
    fi
    
    # Check special flags (e.g., --with-bashhub)
    # This logic is handled by slaane.sh argument parsing
    
    return 1  # Disabled
}

# Get modules by type (core, default, optional)
get_modules_by_type() {
    local type="$1"  # core, default, optional
    local modules=($(discover_modules))
    local result=()
    
    for module in "${modules[@]}"; do
        if ! load_module_metadata "$module"; then
            continue
        fi
        
        case "$type" in
            core)
                if [[ "${MODULE_IS_CORE:-false}" == "true" ]]; then
                    result+=("$module")
                fi
                ;;
            default)
                if [[ "${MODULE_ENABLED_BY_DEFAULT:-false}" == "true" ]] && \
                   [[ "${MODULE_IS_CORE:-false}" != "true" ]]; then
                    result+=("$module")
                fi
                ;;
            optional)
                if [[ "${MODULE_ENABLED_BY_DEFAULT:-false}" == "false" ]]; then
                    result+=("$module")
                fi
                ;;
        esac
    done
    
    echo "${result[@]}"
}

# Check if module should be skipped (from CLI flags)
check_module_should_skip() {
    local module_name="$1"
    local module_base="${module_name}"
    
    # Check SKIP_MODULES array (set by slaane.sh)
    if [[ -n "${SKIP_MODULES:-}" ]]; then
        for skip in "${SKIP_MODULES[@]}"; do
            if [[ "$skip" == "$module_base" ]] || [[ "$skip" == "$module_name" ]]; then
                return 0  # Should skip
            fi
        done
    fi
    
    return 1  # Don't skip
}

