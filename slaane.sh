#!/usr/bin/env bash
# Slaane.sh - Portable bash environment installer
# "Excess in all things - especially shell configuration"

set -u

# ============================================================================
# Bootstrap: Handle curl|bash execution
# ============================================================================

BOOTSTRAP_BRANCH="${BOOTSTRAP_BRANCH:-master}"
for arg in "$@"; do
    [[ "$arg" == --branch=* ]] && BOOTSTRAP_BRANCH="${arg#*=}"
done

# Determine script directory
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
    _source="${BASH_SOURCE[0]}"
    while [[ -L "$_source" ]]; do
        _dir="$(cd -P "$(dirname "$_source")" && pwd)"
        _source="$(readlink "$_source")"
        [[ $_source != /* ]] && _source="$_dir/$_source"
    done
    SCRIPT_DIR="$(cd "$(dirname "$_source")" && pwd)" 2>/dev/null || true
    unset _source _dir
fi

# If piped to bash, download repo first
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    TEMP_DIR=$(mktemp -d -t slaane.sh.XXXXXX)
    trap "rm -rf '$TEMP_DIR'" EXIT
    
    REPO_URL="https://github.com/DaiTengu/slaane.sh/archive/refs/heads/${BOOTSTRAP_BRANCH}.tar.gz"
    
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget -qO-"
    else
        echo "ERROR: curl or wget required"
        exit 1
    fi
    
    echo "Downloading slaane.sh from branch: ${BOOTSTRAP_BRANCH}..."
    (cd "$TEMP_DIR" && $DOWNLOAD_CMD "$REPO_URL" | tar -xzf -) || exit 1
    
    BRANCH_DIR=$(echo "$BOOTSTRAP_BRANCH" | tr '/' '-')
    NEW_ARGS=()
    for arg in "$@"; do
        [[ "$arg" != --branch=* ]] && NEW_ARGS+=("$arg")
    done
    export BOOTSTRAP_BRANCH  # Pass branch to child script for git clone
    exec bash "$TEMP_DIR/slaane.sh-${BRANCH_DIR}/slaane.sh" "${NEW_ARGS[@]}"
fi

export SCRIPT_DIR

# Source libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/modules.sh"

# Initialize
init_common

# ============================================================================
# Commands
# ============================================================================

cmd_install() {
    local install_prereqs=false
    local force=false
    local minimal=false
    local with_bashhub=false
    local skip_list=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install-prereqs) install_prereqs=true; AUTO_SUDO=true ;;
            --force) force=true ;;
            --minimal) minimal=true ;;
            --global) AUTO_SUDO=true; PREFER_GLOBAL=true ;;
            --with-bashhub) with_bashhub=true ;;
            --skip=*) skip_list="${1#*=}" ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done
    
    export FORCE_INSTALL="$force"
    
    # Clone to permanent location if running from temp
    if [[ "$SCRIPT_DIR" == /tmp/* ]]; then
        local target="$HOME/slaane.sh"
        if [[ -d "$target" ]] && [[ "$force" != "true" ]]; then
            log_info "Using existing repo at $target"
            exec bash "$target/slaane.sh" install "$@"
        fi
        [[ -d "$target" ]] && rm -rf "$target"
        git clone -b "${BOOTSTRAP_BRANCH:-master}" https://github.com/DaiTengu/slaane.sh.git "$target"
        exec bash "$target/slaane.sh" install "$@"
    fi
    
    log_info "Starting installation..."
    
    # Install prerequisites if requested
    if [[ "$install_prereqs" == "true" ]]; then
        install_prerequisites
    fi
    
    # Build module list
    local -a modules=()
    local -a skip=()
    IFS=',' read -ra skip <<< "$skip_list"
    
    # Always install core modules
    while IFS= read -r mod; do
        [[ -n "$mod" ]] && modules+=("$mod")
    done < <(get_core_modules)
    
    # Add default modules unless minimal
    if [[ "$minimal" != "true" ]]; then
        while IFS= read -r mod; do
            [[ -n "$mod" ]] && modules+=("$mod")
        done < <(get_default_modules)
    fi
    
    # Add bashhub if requested
    if [[ "$with_bashhub" == "true" ]]; then
        modules+=("bashhub")
    fi
    
    # Install modules
    local failed=0
    local critical=0
    
    for mod in "${modules[@]}"; do
        # Check skip list
        for s in "${skip[@]}"; do
            [[ "$mod" == "$s" ]] && { log_info "Skipping $mod"; continue 2; }
        done
        
        echo ""
        log_info "========================================"
        log_info "Installing: $mod"
        log_info "========================================"
        
        if install_module "$mod"; then
            :
        else
            ((failed++))
            is_core_module "$mod" && ((critical++))
        fi
    done
    
    # Install config files
    install_configs
    
    # Create symlink
    mkdir -p "$HOME/.local/bin"
    ln -sf "$SCRIPT_DIR/slaane.sh" "$HOME/.local/bin/slaane.sh"
    
    echo ""
    if [[ $critical -gt 0 ]]; then
        log_error "Installation failed: $critical core module(s) failed"
        return 1
    elif [[ $failed -gt 0 ]]; then
        log_warning "Completed with $failed non-critical failure(s)"
    else
        log_success "Installation complete!"
    fi
    
    log_info "Run 'source ~/.bashrc' or start a new shell to activate"
}

cmd_update() {
    local component=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --component) component="$2"; shift 2 ;;
            --branch) git fetch && git checkout "$2" && git pull; return $? ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
    
    if [[ "$component" == "all" ]]; then
        for mod in $(discover_modules); do
            check_installed "$mod" && update_module "$mod"
        done
    elif [[ -n "$component" ]]; then
        update_module "$component"
    else
        log_info "Updating repository..."
        git pull
    fi
}

cmd_uninstall() {
    local module=""
    local purge=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --module) module="$2"; shift 2 ;;
            --purge) purge=true; module="all"; shift ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
    
    [[ -z "$module" ]] && { log_error "Specify --module <name> or --module all"; exit 1; }
    
    # Confirmation
    echo ""
    if [[ "$module" == "all" ]]; then
        log_warning "This will uninstall ALL modules and restore original .bashrc"
        [[ "$purge" == "true" ]] && log_warning "AND remove slaane.sh completely"
    else
        log_warning "This will uninstall: $module"
    fi
    read -p "Continue? (yes/no): " -r
    [[ "$REPLY" =~ ^[Yy][Ee][Ss]$ ]] || { log_info "Cancelled"; return 0; }
    
    if [[ "$module" == "all" ]]; then
        for mod in $(discover_modules); do
            check_installed "$mod" && uninstall_module "$mod"
        done
        
        # Restore bashrc
        [[ -f "$HOME/.bashrc.pre-slaanesh" ]] && cp "$HOME/.bashrc.pre-slaanesh" "$HOME/.bashrc"
        rm -f "$HOME/.local/bin/slaane.sh"
        
        if [[ "$purge" == "true" ]]; then
            rm -rf "$HOME/.slaane.sh" "$HOME/.bashrc.pre-slaanesh"
            [[ "$SCRIPT_DIR" == "$HOME"* ]] && rm -rf "$SCRIPT_DIR"
            log_success "Completely purged"
        else
            log_success "All modules uninstalled"
        fi
    else
        uninstall_module "$module"
    fi
}

cmd_list() {
    local show_installed=false
    
    [[ "${1:-}" == "--installed" ]] && show_installed=true
    
    echo ""
    if [[ "$show_installed" == "true" ]]; then
        log_info "Installed modules:"
        for mod in $(discover_modules); do
            check_installed "$mod" && echo "  - $mod"
        done
    else
        log_info "Available modules:"
        for mod in $(discover_modules); do
            local status="" flags=""
            check_installed "$mod" && status=" [INSTALLED]"
            is_core_module "$mod" && flags=" (core)"
            is_optional_module "$mod" && flags=" (optional)"
            echo "  - ${mod}${status}${flags}: $(get_module_desc "$mod")"
        done
    fi
}

cmd_test() {
    local module="${2:-}"
    
    [[ "$1" != "--module" ]] && { log_error "Usage: test --module <name|all>"; exit 1; }
    
    local failed=0
    local tested=0
    
    if [[ "$module" == "all" ]]; then
        for mod in $(discover_modules); do
            ((tested++))
            echo -n "Testing $mod... "
            if check_installed "$mod"; then
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}NOT INSTALLED${NC}"
                ((failed++))
            fi
        done
    else
        ((tested++))
        if check_installed "$module"; then
            log_success "$module is installed"
        else
            log_error "$module is NOT installed"
            ((failed++))
        fi
    fi
    
    echo ""
    log_info "Tested: $tested, Failed: $failed"
    return $failed
}

# ============================================================================
# Helpers
# ============================================================================

install_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=()
    for cmd in git curl make gawk; do
        command_exists "$cmd" || missing+=("$cmd")
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installing: ${missing[*]}"
        local pkgs=()
        for m in "${missing[@]}"; do
            pkgs+=("$(get_package_names "$m")")
        done
        run_as_root $PKG_INSTALL "${pkgs[@]}"
    fi
    
    log_success "Prerequisites satisfied"
}

install_configs() {
    log_info "Installing configuration files..."
    
    # Backup and install bashrc
    if [[ -f "$HOME/.bashrc" ]] && [[ ! -f "$HOME/.bashrc.pre-slaanesh" ]]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.pre-slaanesh"
        log_info "Backed up .bashrc to .bashrc.pre-slaanesh"
    fi
    
    if [[ -f "$SCRIPT_DIR/config/bashrc.template" ]]; then
        cp "$SCRIPT_DIR/config/bashrc.template" "$HOME/.bashrc"
        log_success ".bashrc installed"
    fi
    
    # Install blerc if not present
    if [[ -f "$SCRIPT_DIR/config/blerc" ]] && [[ ! -f "$HOME/.blerc" ]]; then
        cp "$SCRIPT_DIR/config/blerc" "$HOME/.blerc"
        log_success ".blerc installed"
    fi
}

show_help() {
    cat <<'EOF'
Slaane.sh - Portable bash environment installer

Usage: slaane.sh <command> [options]

Commands:
  install     Install shell environment
  update      Update repository or modules
  uninstall   Remove modules
  list        List available/installed modules
  test        Test module installation
  help        Show this help

Install Options:
  --install-prereqs   Install missing prerequisites (git, curl, make, gawk)
  --force             Force reinstall of modules
  --minimal           Install only core modules (bash-it, blesh, fzf)
  --global            Prefer system package manager installations
  --with-bashhub      Include bashhub (requires account)
  --skip=mod1,mod2    Skip specific modules
  --branch=<branch>   Install from specific git branch

Update Options:
  --component <name>  Update specific module
  --component all     Update all installed modules
  --branch <branch>   Switch to git branch

Uninstall Options:
  --module <name>     Uninstall specific module
  --module all        Uninstall all modules
  --purge             Complete removal including slaane.sh

List Options:
  --installed         Show only installed modules

Examples:
  slaane.sh install --install-prereqs
  slaane.sh install --minimal --skip=nano
  slaane.sh update --component all
  slaane.sh uninstall --module pyenv
  slaane.sh list --installed
EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    local cmd="${1:-help}"
    shift || true
    
    # Filter --branch from args (only used in bootstrap)
    local args=()
    for arg in "$@"; do
        [[ "$arg" != --branch=* ]] && args+=("$arg")
    done
    
    case "$cmd" in
        install)   cmd_install "${args[@]}" ;;
        update)    cmd_update "${args[@]}" ;;
        uninstall) cmd_uninstall "${args[@]}" ;;
        list)      cmd_list "${args[@]}" ;;
        test)      cmd_test "${args[@]}" ;;
        help|--help|-h) show_help ;;
        *) log_error "Unknown command: $cmd"; show_help; exit 1 ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
