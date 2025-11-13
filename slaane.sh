#!/usr/bin/env bash
# Slaane.sh Master Script - Unified interface for install/update/uninstall/list/test

# Parse --branch flag early for bootstrap (before anything else)
# Check environment variable first (set during re-exec from bootstrap)
BOOTSTRAP_BRANCH="${BOOTSTRAP_BRANCH:-master}"
for arg in "$@"; do
    if [[ "$arg" == --branch=* ]]; then
        BOOTSTRAP_BRANCH="${arg#*=}"
    fi
done

# Bootstrap: If running from pipe (curl | bash), download repo first
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
    # Resolve symlinks to get the real script location
    _source="${BASH_SOURCE[0]}"
    while [[ -L "$_source" ]]; do
        _dir="$(cd -P "$(dirname "$_source")" && pwd)"
        _source="$(readlink "$_source")"
        [[ $_source != /* ]] && _source="$_dir/$_source"
    done
    SCRIPT_DIR="$(cd "$(dirname "$_source")" && pwd)" 2>/dev/null || true
    unset _source _dir
fi

# Now set -u after we've handled potentially unset variables
set -u

# If we couldn't determine a valid script directory, we're being piped
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    # We're being piped to bash or sourced, need to download the repo
    TEMP_DIR=$(mktemp -d -t slaane.sh.XXXXXX)
    trap "rm -rf '$TEMP_DIR'" EXIT
    
    REPO_URL="https://github.com/DaiTengu/slaane.sh/archive/refs/heads/${BOOTSTRAP_BRANCH}.tar.gz"
    
    # Check if curl or wget is available
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget -qO-"
    else
        echo "ERROR: curl or wget is required to download the repository."
        echo ""
        echo "Please either:"
        echo "  1. Install curl or wget first, then run this command again"
        echo "  2. Clone the repository manually:"
        echo "     git clone https://github.com/DaiTengu/slaane.sh.git ~/slaane.sh"
        echo "     cd ~/slaane.sh && ./slaane.sh install --install-prereqs"
        echo ""
        exit 1
    fi
    
    # Check if tar is available
    if ! command -v tar >/dev/null 2>&1; then
        echo "ERROR: tar is required to extract the repository."
        echo ""
        echo "Please install tar, then run this command again."
        exit 1
    fi
    
    echo "Downloading Slaane.sh repository from branch: ${BOOTSTRAP_BRANCH}..."
    if ! (cd "$TEMP_DIR" && $DOWNLOAD_CMD "$REPO_URL" | tar -xzf - 2>/dev/null); then
        echo "ERROR: Failed to download or extract repository from branch '${BOOTSTRAP_BRANCH}'."
        echo "Please verify the branch name is correct."
        exit 1
    fi
    
    # GitHub archives extract to: slaane.sh-<branch>/
    # Need to sanitize branch name for directory (/ becomes -)
    BRANCH_DIR=$(echo "$BOOTSTRAP_BRANCH" | tr '/' '-')
    
    # Re-execute the actual slaane.sh script with original arguments
    # Filter out --branch flag as it's only for bootstrap
    # Pass BOOTSTRAP_BRANCH via environment variable
    NEW_ARGS=()
    for arg in "$@"; do
        if [[ "$arg" != --branch=* ]]; then
            NEW_ARGS+=("$arg")
        fi
    done
    BOOTSTRAP_BRANCH="$BOOTSTRAP_BRANCH" exec bash "$TEMP_DIR/slaane.sh-${BRANCH_DIR}/slaane.sh" "${NEW_ARGS[@]}"
fi

# Source common libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/module-api.sh"
source "$SCRIPT_DIR/lib/module-handlers.sh"
source "$SCRIPT_DIR/lib/state-tracking.sh"
source "$SCRIPT_DIR/lib/config-handler.sh"

# Initialize OS detection
init_common

# Initialize state tracking early (ensures state directory exists)
init_state_tracking

# ============================================================================
# Subcommands
# ============================================================================

# Install subcommand
cmd_install() {
    local install_prereqs=false
    local force_install=false
    local with_bashhub=false
    local minimal_install=false
    local prefer_global=false
    local skip_modules=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install-prereqs)
                install_prereqs=true
                shift
                ;;
            --force)
                force_install=true
                shift
                ;;
            --with-bashhub)
                with_bashhub=true
                shift
                ;;
            --minimal)
                minimal_install=true
                shift
                ;;
            --global)
                prefer_global=true
                shift
                ;;
            --skip=*)
                local skip_list="${1#*=}"
                IFS=',' read -ra skip_modules <<< "$skip_list"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Export flags
    export INSTALL_PREREQS="$install_prereqs"
    export FORCE_INSTALL="$force_install"
    export WITH_BASHHUB="$with_bashhub"
    export SKIP_MODULES=("${skip_modules[@]}")
    export MINIMAL_INSTALL="$minimal_install"
    export PREFER_GLOBAL="$prefer_global"
    
    # Set AUTO_SUDO if --install-prereqs or --global is set
    if [[ "$install_prereqs" == "true" ]] || [[ "$prefer_global" == "true" ]]; then
        export AUTO_SUDO="true"
    fi
    
    log_info "Starting Slaane.sh installation..."
    
    # If running from a temp directory (bootstrap), clone repo to permanent location
    if [[ "$SCRIPT_DIR" == /tmp/* ]] || [[ "$SCRIPT_DIR" == /var/tmp/* ]]; then
        local target_dir="$HOME/slaane.sh"
        
        # Check if valid installation exists
        if [[ -f "$target_dir/slaane.sh" ]] && [[ "$force_install" != "true" ]]; then
            log_info "Using existing repository at $target_dir"
            exec bash "$target_dir/slaane.sh" install "$@"
        fi
        
        # Remove incomplete/invalid directory if it exists
        if [[ -d "$target_dir" ]]; then
            log_info "Removing incomplete repository at $target_dir..."
            rm -rf "$target_dir"
        fi
        
        # Clone the repository
        log_info "Cloning repository to $target_dir..."
        local clone_branch="${BOOTSTRAP_BRANCH:-master}"
        
        if git clone -b "$clone_branch" https://github.com/DaiTengu/slaane.sh.git "$target_dir"; then
            log_success "Repository cloned to $target_dir"
            exec bash "$target_dir/slaane.sh" install "$@"
        else
            log_error "Failed to clone repository"
            return 1
        fi
    fi
    
    # Handle prerequisites if requested
    if [[ "$install_prereqs" == "true" ]]; then
        log_info "Installing prerequisites..."
        
        # Install basic prerequisites needed for installation
        local missing_prereqs=()
        
        if ! command_exists git; then
            missing_prereqs+=("git")
        fi
        if ! command_exists curl && ! command_exists wget; then
            missing_prereqs+=("curl")
        fi
        if ! command_exists make; then
            missing_prereqs+=("make")
        fi
        if ! command_exists gawk; then
            missing_prereqs+=("gawk")
        fi
        
        if [[ ${#missing_prereqs[@]} -gt 0 ]]; then
            log_info "Installing missing prerequisites: ${missing_prereqs[*]}..."
            
            if [[ "$PKG_MANAGER" != "unknown" ]]; then
                local packages=()
                for prereq in "${missing_prereqs[@]}"; do
                    local pkg=$(get_package_names "$prereq" 2>/dev/null || echo "$prereq")
                    packages+=("$pkg")
                done
                
                if run_as_root $PKG_INSTALL "${packages[@]}"; then
                    log_success "Prerequisites installed"
                else
                    log_error "Failed to install prerequisites"
                    return 1
                fi
            else
                log_error "Cannot determine package manager for prerequisite installation"
                return 1
            fi
        else
            log_info "All prerequisites are already installed"
        fi
    fi
    
    # Discover all modules
    local all_modules=($(discover_modules))
    if [[ ${#all_modules[@]} -eq 0 ]]; then
        log_error "No modules found"
        return 1
    fi
    
    # Determine which modules to install
    local modules_to_install=()
    
    if [[ "$minimal_install" == "true" ]]; then
        # Only core modules
        modules_to_install=($(get_modules_by_type core))
    else
        # Default modules (core + default)
        local core_modules=($(get_modules_by_type core))
        local default_modules=($(get_modules_by_type default))
        
        modules_to_install=("${core_modules[@]}" "${default_modules[@]}")
        
        # Add optional modules if flagged
        if [[ "$with_bashhub" == "true" ]]; then
            if [[ " ${all_modules[@]} " =~ " bashhub " ]]; then
                modules_to_install+=("bashhub")
            fi
        fi
    fi
    
    # Resolve dependencies for all modules
    local resolved_modules=()
    local visited_modules=()
    local dependency_errors=0
    
    # Function to add module and its dependencies (with cycle detection)
    add_module_with_deps() {
        local module="$1"
        local current_path="${2:-}"  # Track path for cycle detection
        
        # Check for circular dependencies
        if [[ "$current_path" =~ (^|:)$module(:|$) ]]; then
            log_error "Circular dependency detected: ${current_path}:${module}"
            ((dependency_errors++))
            return 1
        fi
        
        # Skip if already resolved
        if [[ " ${resolved_modules[@]} " =~ " ${module} " ]]; then
            return 0
        fi
        
        # Mark as visited in current resolution path
        local new_path="${current_path:+${current_path}:}${module}"
        
        # Load metadata to get dependencies
        if ! load_module_metadata "$module"; then
            log_error "Cannot resolve dependencies for $module: metadata not found"
            ((dependency_errors++))
            return 1
        fi
        
        # Add dependencies first (depth-first)
        if [[ -n "${MODULE_DEPENDS:-}" ]]; then
            local deps=($MODULE_DEPENDS)
            for dep in "${deps[@]}"; do
                # Check if dependency module exists
                if [[ ! -f "$SCRIPT_DIR/modules/${dep}.sh" ]]; then
                    log_error "Module $module: Dependency '$dep' not found"
                    ((dependency_errors++))
                    continue
                fi
                
                # Recursively resolve dependency
                if ! add_module_with_deps "$dep" "$new_path"; then
                    ((dependency_errors++))
                fi
            done
        fi
        
        # Add module itself (after dependencies)
        if [[ ! " ${resolved_modules[@]} " =~ " ${module} " ]]; then
            resolved_modules+=("$module")
        fi
        
        return 0
    }
    
    # Resolve all modules
    for module in "${modules_to_install[@]}"; do
        if check_module_should_skip "$module"; then
            continue
        fi
        if ! add_module_with_deps "$module"; then
            log_warning "Failed to resolve dependencies for $module"
        fi
    done
    
    # Check for dependency resolution errors
    if [[ $dependency_errors -gt 0 ]]; then
        log_error "Dependency resolution failed with $dependency_errors error(s)"
        return 1
    fi
    
    # Install modules
    local failed_modules=()
    local critical_failures=0
    
    for module in "${resolved_modules[@]}"; do
        if check_module_should_skip "$module"; then
            log_info "Skipping module: $module"
            continue
        fi
        
        log_info "========================================"
        log_info "Installing module: $module"
        log_info "========================================"
        
        # Load metadata to check if core
        local is_core=false
        if load_module_metadata "$module"; then
            if [[ "${MODULE_IS_CORE:-false}" == "true" ]]; then
                is_core=true
            fi
        else
            log_error "Cannot load metadata for $module"
            failed_modules+=("$module")
            if [[ "$is_core" == "true" ]]; then
                ((critical_failures++))
            fi
            continue
        fi
        
        # Install module
        if install_module_generic "$module"; then
            # Handle config files
            handle_module_config_files "$module"
            
            # Track installed module
            track_module_installed "$module"
            
            log_success "Module $module installed successfully"
        else
            # Installation failed
            if [[ "$is_core" == "true" ]]; then
                log_error "Critical module $module failed to install"
                failed_modules+=("$module")
                ((critical_failures++))
            else
                log_warning "Module $module failed to install (non-critical)"
                failed_modules+=("$module")
            fi
        fi
    done
    
    # Install main config files (.bashrc)
    install_configuration_files
    
    # Create symlink to ~/.local/bin
    create_symlink
    
    # Summary
    echo ""
    if [[ $critical_failures -gt 0 ]]; then
        log_error "Installation failed: $critical_failures critical module(s) failed"
        return 1
    elif [[ ${#failed_modules[@]} -gt 0 ]]; then
        log_warning "Installation completed with ${#failed_modules[@]} non-critical failure(s)"
        return 0
    else
        log_success "All modules installed successfully"
        return 0
    fi
}

# Update repository branch
# Switches to specified git branch and updates
update_repository_branch() {
    local branch="$1"
    
    log_info "Switching to branch: $branch"
    if ! git fetch && git checkout "$branch" && git pull; then
        log_error "Failed to switch branch: $branch"
        log_error "Suggestion: Check that branch exists and you have network access"
        return 1
    fi
    log_success "Switched to branch: $branch"
    return 0
}

# Update repository (default: current branch)
update_repository() {
    log_info "Updating Slaane.sh repository..."
    if git pull; then
        log_success "Repository updated"
        return 0
    else
        log_error "Failed to update repository"
        log_error "Suggestion: Check network connection and git status"
        return 1
    fi
}

# Update all installed modules
update_all_modules() {
    local installed_modules=($(get_installed_modules))
    if [[ ${#installed_modules[@]} -eq 0 ]]; then
        log_info "No modules installed"
        return 0
    fi
    
    log_info "Updating all installed modules..."
    local failed=0
    for module in "${installed_modules[@]}"; do
        log_info "Updating module: $module"
        if ! update_module_generic "$module"; then
            log_warning "Failed to update: $module"
            ((failed++))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_success "All modules updated successfully"
        return 0
    else
        log_warning "$failed module(s) failed to update"
        return 1
    fi
}

# Update specific module
update_single_module() {
    local module="$1"
    
    if ! is_module_installed "$module"; then
        log_warning "Module $module is not installed"
        log_error "Suggestion: Install it first with 'slaane.sh install'"
        return 1
    fi
    
    log_info "Updating module: $module"
    if update_module_generic "$module"; then
        log_success "Module $module updated"
        return 0
    else
        log_error "Failed to update module $module"
        log_error "Suggestion: Check module logs above for specific errors"
        return 1
    fi
}

# Update subcommand
# Handles repository updates, branch switching, and module updates
cmd_update() {
    local component=""
    local branch=""
    local update_all=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --component)
                if [[ "$2" == "all" ]]; then
                    update_all=true
                else
                    component="$2"
                fi
                shift 2
                ;;
            --branch)
                branch="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Handle branch switching (takes precedence)
    if [[ -n "$branch" ]]; then
        update_repository_branch "$branch"
        return $?
    fi
    
    # Update component(s) if specified
    if [[ "$update_all" == "true" ]]; then
        update_all_modules
        return $?
    elif [[ -n "$component" ]]; then
        update_single_module "$component"
        return $?
    fi
    
    # Default: update repository
    update_repository
    return $?
}

# Uninstall subcommand
cmd_uninstall() {
    local module=""
    local uninstall_all=false
    local purge=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --module)
                if [[ "$2" == "all" ]]; then
                    uninstall_all=true
                else
                    module="$2"
                fi
                shift 2
                ;;
            --purge)
                purge=true
                uninstall_all=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Confirmation prompt
    if [[ "$uninstall_all" == "true" ]]; then
        echo ""
        if [[ "$purge" == "true" ]]; then
            log_warning "This will remove ALL installed modules, restore original .bashrc,"
            log_warning "and completely remove the slaane.sh installation from this system."
        else
            log_warning "This will remove ALL installed modules and restore original .bashrc"
        fi
        read -p "Continue with uninstall? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Uninstall cancelled"
            return 0
        fi
    elif [[ -n "$module" ]]; then
        echo ""
        log_warning "This will remove module: $module"
        read -p "Continue with uninstall? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Uninstall cancelled"
            return 0
        fi
    else
        log_error "Specify --module <name> or --module all"
        show_usage
        return 1
    fi
    
    # Uninstall
    if [[ "$uninstall_all" == "true" ]]; then
        local installed_modules=($(get_installed_modules))
        
        for mod in "${installed_modules[@]}"; do
            log_info "Uninstalling module: $mod"
            uninstall_module_generic "$mod" || log_warning "Failed to uninstall: $mod"
            
            # If purging, also remove config files
            if [[ "$purge" == "true" ]]; then
                local mod_file="$SCRIPT_DIR/modules/$mod.sh"
                if [[ -f "$mod_file" ]] && extract_embedded_metadata "$mod_file"; then
                    if [[ -n "${MODULE_CONFIG_FILES:-}" ]]; then
                        for config_file in $MODULE_CONFIG_FILES; do
                            if [[ -e "$config_file" ]]; then
                                rm -rf "$config_file"
                                log_info "Removed config: $config_file"
                            fi
                        done
                    fi
                fi
            fi
            
            untrack_module "$mod"
        done
        
        # Restore .bashrc
        if [[ -f "$HOME/.bashrc.pre-slaanesh" ]]; then
            log_info "Restoring original .bashrc"
            cp "$HOME/.bashrc.pre-slaanesh" "$HOME/.bashrc"
        fi
        
        # Remove symlink
        if [[ -L "$HOME/.local/bin/slaane.sh" ]]; then
            rm -f "$HOME/.local/bin/slaane.sh"
            log_info "Removed symlink: ~/.local/bin/slaane.sh"
        fi
        
        # Clear tracking
        clear_tracking
        
        # Purge: Remove slaane.sh installation completely
        if [[ "$purge" == "true" ]]; then
            # Remove state tracking directory
            if [[ -d "$HOME/.slaane.sh" ]]; then
                rm -rf "$HOME/.slaane.sh"
                log_info "Removed state directory: ~/.slaane.sh"
            fi
            
            # Remove backup .bashrc
            if [[ -f "$HOME/.bashrc.pre-slaanesh" ]]; then
                rm -f "$HOME/.bashrc.pre-slaanesh"
                log_info "Removed backup: ~/.bashrc.pre-slaanesh"
            fi
            
            # Remove slaane.sh repository
            if [[ -d "$SCRIPT_DIR" ]] && [[ "$SCRIPT_DIR" == "$HOME"* ]]; then
                log_info "Removing slaane.sh repository: $SCRIPT_DIR"
                rm -rf "$SCRIPT_DIR"
                log_success "Slaane.sh completely purged from system"
            else
                log_warning "Not removing $SCRIPT_DIR (not in home directory)"
                log_success "All modules uninstalled (use 'rm -rf $SCRIPT_DIR' to remove repository)"
            fi
        else
            log_success "All modules uninstalled"
        fi
    else
        log_info "Uninstalling module: $module"
        if uninstall_module_generic "$module"; then
            untrack_module "$module"
            log_success "Module $module uninstalled"
        else
            log_error "Failed to uninstall module $module"
            return 1
        fi
    fi
    
    return 0
}

# List subcommand
cmd_list() {
    local list_type="available"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --available)
                list_type="available"
                shift
                ;;
            --installed)
                list_type="installed"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [[ "$list_type" == "installed" ]]; then
        local installed_modules=($(get_installed_modules))
        if [[ ${#installed_modules[@]} -eq 0 ]]; then
            log_info "No modules installed"
            return 0
        fi
        
        echo ""
        log_info "Installed modules:"
        for module in "${installed_modules[@]}"; do
            echo "  - $module"
        done
    else
        # List available modules
        local all_modules=($(discover_modules))
        echo ""
        log_info "Available modules:"
        for module in "${all_modules[@]}"; do
            if load_module_metadata "$module"; then
                local status=""
                if is_module_installed "$module"; then
                    status=" [INSTALLED]"
                fi
                
                local core=""
                if [[ "${MODULE_IS_CORE:-false}" == "true" ]]; then
                    core=" (CORE)"
                fi
                
                echo "  - $module${status}${core}: ${MODULE_DESCRIPTION:-No description}"
            else
                echo "  - $module (metadata error)"
            fi
        done
    fi
    
    return 0
}

# Test subcommand
cmd_test() {
    local module=""
    local test_all=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --module)
                if [[ "$2" == "all" ]]; then
                    test_all=true
                else
                    module="$2"
                fi
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [[ "$test_all" == "true" ]]; then
        local installed_modules=($(get_installed_modules))
        if [[ ${#installed_modules[@]} -eq 0 ]]; then
            log_info "No modules installed to test"
            return 0
        fi
        
        log_info "Testing all installed modules..."
        local failed=0
        for mod in "${installed_modules[@]}"; do
            echo ""
            log_info "Testing module: $mod"
            if ! test_module_generic "$mod"; then
                ((failed++))
            fi
        done
        
        echo ""
        if [[ $failed -eq 0 ]]; then
            log_success "All tests passed"
            return 0
        else
            log_warning "$failed test(s) failed"
            return 1
        fi
    elif [[ -n "$module" ]]; then
        log_info "Testing module: $module"
        if test_module_generic "$module"; then
            log_success "Test passed"
            return 0
        else
            log_error "Test failed"
            return 1
        fi
    else
        log_error "Specify --module <name> or --module all"
        show_usage
        return 1
    fi
}

# Help/Usage
show_usage() {
    cat <<EOF
Slaane.sh - Master script for managing your shell environment

Usage: slaane.sh <command> [options]

Commands:
  install              Install all modules (or selected modules)
  update               Update slaane.sh repository or modules
  uninstall            Remove installed modules
  list                 List available or installed modules
  test                 Test installed modules
  help                 Show this help message

Install Options:
  --install-prereqs    Automatically install missing prerequisites
  --force              Force reinstallation of modules
  --with-bashhub       Install bashhub module
  --minimal            Install only core modules
  --global             Prefer system-wide (package manager) installations
  --skip=<modules>     Skip specific modules (comma-separated)
  --branch=<branch>    Install from specific git branch (bootstrap only)

Update Options:
  --component <name>    Update specific component
  --component all      Update all installed components
  --branch <branch>    Switch to git branch and update

Uninstall Options:
  --module <name>      Uninstall specific module
  --module all         Uninstall all modules
  --purge              Complete removal (all modules + slaane.sh itself)

List Options:
  --available          List all available modules (default)
  --installed          List installed modules

Test Options:
  --module <name>      Test specific module
  --module all         Test all installed modules

Examples:
  slaane.sh install --install-prereqs
  slaane.sh update --component bash-it
  slaane.sh uninstall --module all
  slaane.sh uninstall --purge
  slaane.sh list --installed
  slaane.sh test --module all
EOF
}

# Install configuration files
install_configuration_files() {
    log_info "Installing configuration files..."
    
    local bashrc_template="$SCRIPT_DIR/config/bashrc.template"
    local blerc_file="$SCRIPT_DIR/config/blerc"
    local backup_suffix=".pre-slaanesh"
    
    # Install .bashrc
    if [[ -f "$bashrc_template" ]]; then
        if [[ -f "$HOME/.bashrc" ]]; then
            log_info "Backing up existing .bashrc to .bashrc${backup_suffix}"
            cp "$HOME/.bashrc" "$HOME/.bashrc${backup_suffix}"
        fi
        
        log_info "Installing .bashrc..."
        cp "$bashrc_template" "$HOME/.bashrc"
        log_success ".bashrc installed"
    else
        log_warning ".bashrc template not found, skipping"
    fi
    
    # Install .blerc (only if it doesn't exist)
    if [[ -f "$blerc_file" ]]; then
        if [[ -f "$HOME/.blerc" ]]; then
            log_info ".blerc already exists, not overwriting"
        else
            log_info "Installing .blerc..."
            cp "$blerc_file" "$HOME/.blerc"
            log_success ".blerc installed"
        fi
    else
        log_warning ".blerc file not found, skipping"
    fi
    
    return 0
}

# Create symlink to ~/.local/bin
create_symlink() {
    local bin_dir="$HOME/.local/bin"
    local symlink="$bin_dir/slaane.sh"
    
    mkdir -p "$bin_dir"
    
    if [[ -L "$symlink" ]]; then
        # Update existing symlink
        rm -f "$symlink"
    fi
    
    ln -s "$SCRIPT_DIR/slaane.sh" "$symlink"
    log_success "Created symlink: $symlink"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    shift || true
    
    # Filter out --branch flag (only used during bootstrap)
    local filtered_args=()
    for arg in "$@"; do
        if [[ "$arg" != --branch=* ]]; then
            filtered_args+=("$arg")
        fi
    done
    
    case "$command" in
        install)
            cmd_install "${filtered_args[@]}"
            ;;
        update)
            cmd_update "${filtered_args[@]}"
            ;;
        uninstall)
            cmd_uninstall "${filtered_args[@]}"
            ;;
        list)
            cmd_list "${filtered_args[@]}"
            ;;
        test)
            cmd_test "${filtered_args[@]}"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

