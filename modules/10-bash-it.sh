#!/usr/bin/env bash
# Module: bash-it installation
# Installs bash-it framework and configures enabled components

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

BASH_IT_REPO="https://github.com/Bash-it/bash-it.git"
BASH_IT_DIR="$HOME/.bash_it"

check_bash_it_installed() {
    [[ -d "$BASH_IT_DIR" ]] && [[ -f "$BASH_IT_DIR/bash_it.sh" ]]
}

install_bash_it() {
    log_info "Installing bash-it..."
    
    if check_bash_it_installed && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        log_warning "bash-it is already installed at $BASH_IT_DIR"
        log_info "Use --force to reinstall"
        return 0
    fi
    
    if [[ -d "$BASH_IT_DIR" ]] && [[ "${FORCE_INSTALL:-}" == "true" ]]; then
        log_warning "Removing existing bash-it installation..."
        rm -rf "$BASH_IT_DIR"
    fi
    
    # Clone bash-it
    log_info "Cloning bash-it from $BASH_IT_REPO..."
    if ! git clone --depth=1 "$BASH_IT_REPO" "$BASH_IT_DIR"; then
        log_error "Failed to clone bash-it"
        return 1
    fi
    
    # Run bash-it installer (non-interactive)
    log_info "Running bash-it installation..."
    if ! bash "$BASH_IT_DIR/install.sh" --silent --no-modify-config; then
        log_error "bash-it installation failed"
        return 1
    fi
    
    log_success "bash-it installed successfully"
    return 0
}

enable_bash_it_component() {
    local component_type="$1"  # alias, plugin, or completion
    local component_name="$2"
    
    if ! check_bash_it_installed; then
        log_error "bash-it is not installed"
        return 1
    fi
    
    # Determine directory name (completion is singular, aliases/plugins are plural)
    local dir_name=""
    case "$component_type" in
        alias)
            dir_name="aliases"
            ;;
        plugin)
            dir_name="plugins"
            ;;
        completion)
            dir_name="completion"
            ;;
        *)
            log_error "Unknown component type: $component_type"
            return 1
            ;;
    esac
    
    # Determine file extension (aliases uses plural, plugin/completion use singular)
    local file_ext=""
    case "$component_type" in
        alias)
            file_ext="aliases"
            ;;
        plugin)
            file_ext="plugin"
            ;;
        completion)
            file_ext="completion"
            ;;
    esac
    
    # Check if component exists
    local available_file="$BASH_IT_DIR/$dir_name/available/${component_name}.${file_ext}.bash"
    if [[ ! -f "$available_file" ]]; then
        log_warning "Component not found: ${component_type}/${component_name}"
        return 1
    fi
    
    # Check if already enabled (enabled files have pattern: priority---name.extension.bash)
    local enabled_dir="$BASH_IT_DIR/enabled"
    if ls "$enabled_dir"/*"---${component_name}.${file_ext}.bash" &>/dev/null; then
        log_info "Component already enabled: ${component_type}/${component_name}"
        return 0
    fi
    
    # Enable using bash-it command
    log_info "Enabling ${component_type}: $component_name"
    bash -c "source '$BASH_IT_DIR/bash_it.sh' && bash-it enable ${component_type} ${component_name}" &>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log_success "Enabled ${component_type}: $component_name"
        return 0
    else
        log_warning "Failed to enable ${component_type}: $component_name"
        return 1
    fi
}

configure_bash_it_components() {
    log_info "Configuring bash-it components..."
    
    local config_file="$SCRIPT_DIR/../config/bash-it-components"
    
    if [[ ! -f "$config_file" ]]; then
        log_warning "Component configuration file not found: $config_file"
        log_info "Skipping component configuration"
        return 0
    fi
    
    local component_type=""
    local enabled_count=0
    local failed_count=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue
        
        # Check for section headers
        if [[ "$line" =~ ^\[(.*)\]$ ]]; then
            component_type="${BASH_REMATCH[1]}"
            log_info "Processing ${component_type}s..."
            continue
        fi
        
        # Enable component
        if [[ -n "$component_type" ]]; then
            if enable_bash_it_component "$component_type" "$line"; then
                ((enabled_count++))
            else
                ((failed_count++))
            fi
        fi
    done < "$config_file"
    
    log_success "Enabled $enabled_count components ($failed_count skipped/failed)"
    return 0
}

install_custom_liquidprompt_theme() {
    log_info "Installing custom liquidprompt theme..."
    
    if ! check_bash_it_installed; then
        log_error "bash-it is not installed"
        return 1
    fi
    
    local theme_dir="$BASH_IT_DIR/themes/liquidprompt"
    local custom_theme="$SCRIPT_DIR/../config/liquidprompt.theme.bash"
    local target_theme="$theme_dir/liquidprompt.theme.bash"
    
    if [[ ! -f "$custom_theme" ]]; then
        log_warning "Custom liquidprompt theme not found: $custom_theme"
        log_info "Skipping custom theme installation"
        return 0
    fi
    
    # Ensure theme directory exists
    # The liquidprompt theme creates its directory when first loaded,
    # so we may need to create it if this is a fresh installation
    if [[ ! -d "$theme_dir" ]]; then
        log_info "Creating liquidprompt theme directory..."
        mkdir -p "$theme_dir" || {
            log_warning "Failed to create theme directory: $theme_dir"
            log_info "Skipping custom theme installation"
            return 0
        }
    fi
    
    # Backup existing theme if it exists and we're not forcing
    if [[ -f "$target_theme" ]] && [[ "${FORCE_INSTALL:-}" != "true" ]]; then
        local backup_file="${target_theme}.pre-slaanesh-$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing theme to: $(basename "$backup_file")"
        cp "$target_theme" "$backup_file"
    fi
    
    # Copy custom theme
    log_info "Installing custom liquidprompt theme (with git branch display fix)..."
    if cp "$custom_theme" "$target_theme"; then
        log_success "Custom liquidprompt theme installed successfully"
        return 0
    else
        log_error "Failed to install custom liquidprompt theme"
        return 1
    fi
}

# Main module execution
main_bash_it() {
    if ! install_bash_it; then
        return 1
    fi
    
    if ! configure_bash_it_components; then
        log_warning "Some components failed to enable, but bash-it is installed"
    fi
    
    # Install custom liquidprompt theme after components are configured
    # This ensures liquidprompt is set up and the theme directory exists
    if ! install_custom_liquidprompt_theme; then
        log_warning "Custom liquidprompt theme installation failed, but continuing..."
    fi
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_common
    main_bash_it
fi

