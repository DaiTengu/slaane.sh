#!/usr/bin/env bash
# Configuration File Handler - Handles MODULE_CONFIG_FILES updates

# Ensure SCRIPT_DIR is set
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source common if needed
if ! declare -f log_info &>/dev/null; then
    source "$SCRIPT_DIR/common.sh"
fi
if ! declare -f load_module_metadata &>/dev/null; then
    source "$SCRIPT_DIR/module-api.sh"
fi

# Config update modes
CONFIG_UPDATE_ASK="ask"
CONFIG_UPDATE_OVERWRITE="overwrite"
CONFIG_UPDATE_KEEP="keep"

# Default to ask mode
CONFIG_UPDATE_MODE="${CONFIG_UPDATE_MODE:-$CONFIG_UPDATE_ASK}"

# Backup config file
backup_config_file() {
    local config_file="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${config_file}.pre-slaanesh-${timestamp}"
    
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$backup_file"
        log_info "Backed up config to: $(basename "$backup_file")"
        return 0
    fi
    
    return 1
}

# Install config file
install_config_file() {
    local source_file="$1"
    local target_file="$2"
    local update_mode="${3:-$CONFIG_UPDATE_MODE}"
    
    # Check if target exists
    if [[ ! -f "$target_file" ]]; then
        # No existing file, just install
        cp "$source_file" "$target_file"
        log_success "Installed config: $target_file"
        return 0
    fi
    
    # Target exists - handle based on update mode
    case "$update_mode" in
        overwrite)
            backup_config_file "$target_file"
            cp "$source_file" "$target_file"
            log_success "Overwritten config: $target_file"
            return 0
            ;;
        keep)
            # Save new as .new
            cp "$source_file" "${target_file}.new"
            log_info "Saved new config as: ${target_file}.new (existing kept)"
            return 0
            ;;
        ask|*)
            # Ask user
            echo ""
            log_warning "Config file already exists: $target_file"
            echo "  [o] Overwrite (backup existing)"
            echo "  [k] Keep existing (save new as .new)"
            echo "  [s] Skip"
            read -p "Choose option (o/k/s): " -r choice
            
            case "$choice" in
                o|O)
                    backup_config_file "$target_file"
                    cp "$source_file" "$target_file"
                    log_success "Overwritten config: $target_file"
                    return 0
                    ;;
                k|K)
                    cp "$source_file" "${target_file}.new"
                    log_info "Saved new config as: ${target_file}.new"
                    return 0
                    ;;
                s|S|*)
                    log_info "Skipped config: $target_file"
                    return 0
                    ;;
            esac
            ;;
    esac
}

# Handle module config files
handle_module_config_files() {
    local module_name="$1"
    
    # Load module metadata
    if ! load_module_metadata "$module_name"; then
        return 0  # No metadata, no config files
    fi
    
    if [[ -z "${MODULE_CONFIG_FILES:-}" ]]; then
        return 0  # No config files
    fi
    
    local config_files=($MODULE_CONFIG_FILES)
    local config_source_dir="$SCRIPT_DIR/config"
    
    for config_file in "${config_files[@]}"; do
        local config_name=$(basename "$config_file")
        local source_file="$config_source_dir/$config_name"
        
        # Check if source template exists
        if [[ ! -f "$source_file" ]]; then
            log_warning "Config template not found: $source_file"
            continue
        fi
        
        # Install config file
        install_config_file "$source_file" "$config_file" "$CONFIG_UPDATE_MODE"
    done
    
    return 0
}

