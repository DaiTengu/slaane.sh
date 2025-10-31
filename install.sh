#!/usr/bin/env bash
# Slaane.sh - Excess in all things, especially shell configuration
# Installs bash-it, ble.sh, fzf, and other development tools

set -e  # Exit on error

# Bootstrap: If running from pipe (curl | bash), download repo first
# Try to determine script directory - if it fails, we're likely being piped
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 2>/dev/null || true
fi

# If we couldn't determine a valid script directory, we're being piped
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    # We're being piped to bash or sourced, need to download the repo
    TEMP_DIR=$(mktemp -d -t slaane.sh.XXXXXX)
    trap "rm -rf '$TEMP_DIR'" EXIT
    
    REPO_URL="https://github.com/DaiTengu/slaane.sh/archive/refs/heads/master.tar.gz"
    
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
        echo "     cd ~/slaane.sh && ./install.sh --install-prereqs"
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
    
    echo "Downloading Slaane.sh repository..."
    if ! (cd "$TEMP_DIR" && $DOWNLOAD_CMD "$REPO_URL" | tar -xzf - 2>/dev/null); then
        echo "ERROR: Failed to download or extract repository."
        exit 1
    fi
    
    # Re-execute the actual install script with original arguments
    exec bash "$TEMP_DIR/slaane.sh-master/install.sh" "$@"
fi

# Normal execution path - set script directory if not already set
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source common functions
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# Configuration
# ============================================================================

# Installation flags
INSTALL_PREREQS=false
FORCE_INSTALL=false
WITH_BASHHUB=false
SKIP_MODULES=()
MINIMAL_INSTALL=false

# Core modules (always installed unless minimal or skipped)
CORE_MODULES=(
    "10-bash-it"
    "20-blesh"
    "30-fzf"
    "40-zoxide"
    "50-pyenv"
    "60-goenv"
    "70-thefuck"
)

# Optional modules (only installed with flags)
OPTIONAL_MODULES=(
    "90-bashhub"
)

# Minimal modules (only these when --minimal is specified)
MINIMAL_MODULES=(
    "10-bash-it"
    "20-blesh"
    "30-fzf"
)

# ============================================================================
# Functions
# ============================================================================

show_usage() {
    cat <<EOF
Slaane.sh - Personal Bash Environment Installer

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    --install-prereqs       Install missing prerequisites using sudo
    --force                 Force reinstall even if components exist
    --with-bashhub          Install bashhub (requires account)
    --skip=MODULE[,MODULE]  Skip specific modules (e.g., --skip=goenv,thefuck)
    --minimal               Install only bash-it, ble.sh, and fzf

Examples:
    # Default installation (all core components)
    $0

    # Install with bashhub
    $0 --with-bashhub

    # Skip some components
    $0 --skip=goenv,thefuck

    # Minimal installation
    $0 --minimal

    # Install prerequisites if missing
    $0 --install-prereqs

Modules:
    Core modules:
        bash-it     - Bash framework
        blesh       - Advanced line editor with syntax highlighting
        fzf         - Fuzzy finder
        zoxide      - Smart directory jumper
        pyenv       - Python version manager
        goenv       - Go version manager
        thefuck     - Command corrector

    Optional modules:
        bashhub     - Cloud command history (requires account)

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            --install-prereqs)
                INSTALL_PREREQS=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --with-bashhub)
                WITH_BASHHUB=true
                shift
                ;;
            --skip=*)
                IFS=',' read -ra SKIP_MODULES <<< "${1#*=}"
                shift
                ;;
            --minimal)
                MINIMAL_INSTALL=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

check_module_should_skip() {
    local module_name="$1"
    
    for skip in "${SKIP_MODULES[@]}"; do
        # Extract module number (e.g., "10-bash-it" -> "bash-it")
        local module_base="${module_name#*-}"
        if [[ "$skip" == "$module_base" ]] || [[ "$skip" == "$module_name" ]]; then
            return 0  # Should skip
        fi
    done
    
    return 1  # Should not skip
}

run_module() {
    local module="$1"
    local module_path="$SCRIPT_DIR/modules/${module}.sh"
    
    if [[ ! -f "$module_path" ]]; then
        log_warning "Module not found: $module"
        return 1
    fi
    
    # Extract module name for display
    local module_name="${module#*-}"
    
    # Check if should skip
    if check_module_should_skip "$module"; then
        log_info "Skipping module: $module_name (--skip)"
        return 0
    fi
    
    log_info "========================================" 
    log_info "Running module: $module_name"
    log_info "========================================"
    
    # Export flags for module use
    export FORCE_INSTALL
    export INSTALL_PREREQS
    export WITH_BASHHUB
    
    # Run the module
    if bash "$module_path"; then
        log_success "Module completed: $module_name"
        return 0
    else
        log_error "Module failed: $module_name"
        return 1
    fi
}

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

show_completion_message() {
    cat <<EOF

${GREEN}========================================${NC}
${GREEN}Installation Complete!${NC}
${GREEN}========================================${NC}

Your portable bash environment has been installed successfully.

${YELLOW}IMPORTANT:${NC} To activate the new environment, please run:

    ${BLUE}source ~/.bashrc${NC}

or restart your shell.

${YELLOW}Installed Components:${NC}
$(if [[ -d "$HOME/.bash_it" ]]; then echo "  ✓ bash-it"; fi)
$(if [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" ]]; then echo "  ✓ ble.sh"; fi)
$(if command -v fzf &>/dev/null; then echo "  ✓ fzf"; fi)
$(if command -v zoxide &>/dev/null; then echo "  ✓ zoxide"; fi)
$(if [[ -d "$HOME/.pyenv" ]]; then echo "  ✓ pyenv"; fi)
$(if [[ -d "$HOME/.goenv" ]]; then echo "  ✓ goenv"; fi)
$(if command -v thefuck &>/dev/null; then echo "  ✓ thefuck"; fi)
$(if [[ -f "$HOME/.bashhub/bashhub.sh" ]]; then echo "  ✓ bashhub"; fi)

${YELLOW}Next Steps:${NC}
  1. Source your new bashrc: ${BLUE}source ~/.bashrc${NC}
  2. Check bash-it: ${BLUE}bash-it show aliases${NC}
  3. Explore ble.sh features (syntax highlighting, auto-suggestions)
  4. Try fuzzy finding: ${BLUE}Ctrl+R${NC} for history, ${BLUE}Ctrl+T${NC} for files
  5. Jump to directories: ${BLUE}z <directory-name>${NC}

${YELLOW}Configuration Files:${NC}
  - Main config: ~/.bashrc
  - ble.sh config: ~/.blerc
  - Local overrides: ~/.bashrc.local (create if needed)

For more information, see the README.md file.

EOF
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    # Print banner
    cat <<EOF
========================================
Slaane.sh installer
========================================

This installer will set up:
  - bash-it framework
  - ble.sh (advanced line editor)
  - fzf (fuzzy finder)
  - zoxide (smart directory jumper)
  - pyenv (Python version manager)
  - goenv (Go version manager)
  - thefuck (command corrector)

EOF

    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize OS detection
    init_common
    
    # Export flags for prerequisite module
    export INSTALL_PREREQS
    
    # Check prerequisites
    log_info "Checking prerequisites..."
    if ! bash "$SCRIPT_DIR/modules/00-prereqs.sh"; then
        log_error "Prerequisites check failed"
        log_info "Run with --install-prereqs to install missing tools"
        exit 1
    fi
    
    # Determine which modules to install
    local modules_to_install=()
    
    if [[ "$MINIMAL_INSTALL" == "true" ]]; then
        log_info "Minimal installation mode"
        modules_to_install=("${MINIMAL_MODULES[@]}")
    else
        modules_to_install=("${CORE_MODULES[@]}")
    fi
    
    # Add optional modules if requested
    if [[ "$WITH_BASHHUB" == "true" ]]; then
        modules_to_install+=("${OPTIONAL_MODULES[@]}")
    fi
    
    # Run installation modules
    local failed_modules=()
    local critical_modules=("10-bash-it" "20-blesh" "30-fzf")
    
    for module in "${modules_to_install[@]}"; do
        if ! run_module "$module"; then
            failed_modules+=("$module")
            
            # Check if this is a critical module
            local is_critical=false
            for critical in "${critical_modules[@]}"; do
                if [[ "$module" == "$critical" ]]; then
                    is_critical=true
                    break
                fi
            done
            
            if [[ "$is_critical" == "true" ]]; then
                log_error "Critical module failed: $module"
                log_error "Cannot continue installation"
                exit 1
            else
                log_warning "Non-critical module failed, continuing..."
            fi
        fi
        echo ""  # Blank line between modules
    done
    
    # Install configuration files
    log_info "========================================"
    log_info "Installing configuration files"
    log_info "========================================"
    install_configuration_files
    echo ""
    
    # Report results
    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        log_warning "Installation completed with some optional components skipped"
        log_warning "Skipped modules: ${failed_modules[*]}"
        log_info "These are non-critical and the environment will work without them"
        echo ""
    fi
    
    # Show completion message
    show_completion_message
    
    # Success even if non-critical modules failed
    exit 0
}

# Run main function
main "$@"

