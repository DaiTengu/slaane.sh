#!/usr/bin/env bash
# Module: Prerequisites checker and installer
# Checks for required system tools and optionally installs them

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Required prerequisites
REQUIRED_COMMANDS=(
    "git"
    "curl"
    "make"
)

# Optional but recommended
OPTIONAL_COMMANDS=(
    "wget"
)

check_prerequisites_module() {
    log_info "Checking prerequisites..."
    
    local missing=()
    local optional_missing=()
    
    # Check required commands
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        else
            log_success "$cmd is installed"
        fi
    done
    
    # Check optional commands
    for cmd in "${OPTIONAL_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            optional_missing+=("$cmd")
        fi
    done
    
    # Check for build tools
    if ! command_exists gcc && ! command_exists cc; then
        missing+=("build-essential")
        log_warning "C compiler not found"
    else
        log_success "C compiler is installed"
    fi
    
    # Report missing optional tools
    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        log_warning "Optional tools not installed: ${optional_missing[*]}"
    fi
    
    # Handle missing required tools
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        return 1
    fi
    
    log_success "All prerequisites are satisfied"
    return 0
}

install_prerequisites_module() {
    log_info "Installing missing prerequisites..."
    
    if [[ "$PKG_MANAGER" == "unknown" ]]; then
        log_error "Cannot determine package manager. Please install prerequisites manually:"
        log_error "  Required: ${REQUIRED_COMMANDS[*]} and build tools (gcc, make, etc.)"
        return 1
    fi
    
    local to_install=()
    
    # Determine what needs to be installed
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            local pkg=$(get_package_names "$cmd")
            if [[ -n "$pkg" ]]; then
                to_install+=($pkg)
            fi
        fi
    done
    
    # Check for build tools
    if ! command_exists gcc && ! command_exists cc; then
        local build_pkg=$(get_package_names "build-essential")
        if [[ -n "$build_pkg" ]]; then
            to_install+=($build_pkg)
        fi
    fi
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_success "All prerequisites already installed"
        return 0
    fi
    
    log_info "Will install: ${to_install[*]}"
    
    # Update package lists
    log_info "Updating package lists..."
    if ! run_as_root $PKG_UPDATE; then
        log_warning "Failed to update package lists (continuing anyway)"
    fi
    
    # Install packages
    log_info "Installing packages..."
    if run_as_root $PKG_INSTALL "${to_install[@]}"; then
        log_success "Prerequisites installed successfully"
        return 0
    else
        log_error "Failed to install prerequisites"
        return 1
    fi
}

show_prereq_help() {
    cat <<EOF

${YELLOW}Missing Prerequisites Detected${NC}

The following tools are required but not found on your system:
$(for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
        echo "  - $cmd"
    fi
done)
$(if ! command_exists gcc && ! command_exists cc; then
    echo "  - C compiler (gcc/build-essential)"
fi)

${BLUE}Options:${NC}

1. Install manually using your package manager:
   
   Debian/Ubuntu:
   $ sudo apt-get update && sudo apt-get install -y git curl make build-essential
   
   RHEL/CentOS/Fedora:
   $ sudo dnf install -y git curl make gcc gcc-c++
   
   Arch Linux:
   $ sudo pacman -S git curl make base-devel

2. Run this installer with the --install-prereqs flag:
   $ ./install.sh --install-prereqs
   
   This will attempt to install missing tools using sudo.

EOF
}

# Main module execution
main_prereqs() {
    init_common
    
    if check_prerequisites_module; then
        return 0
    fi
    
    # If --install-prereqs flag is set, try to install
    if [[ "${INSTALL_PREREQS:-}" == "true" ]]; then
        if install_prerequisites_module; then
            # Recheck after installation
            if check_prerequisites_module; then
                return 0
            fi
        fi
        log_error "Failed to install all prerequisites"
        return 1
    else
        show_prereq_help
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_prereqs
fi

