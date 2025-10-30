#!/usr/bin/env bash
# Common utility functions for portable bash environment installer

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Detect OS and distribution
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$NAME"
        
        # Determine OS family
        case "$OS_ID" in
            ubuntu|debian|linuxmint|pop)
                OS_FAMILY="debian"
                ;;
            rhel|centos|fedora|rocky|almalinux|ol)
                OS_FAMILY="rhel"
                ;;
            arch|manjaro|endeavouros)
                OS_FAMILY="arch"
                ;;
            gentoo)
                OS_FAMILY="gentoo"
                ;;
            *)
                OS_FAMILY="unknown"
                ;;
        esac
    else
        OS_ID="unknown"
        OS_FAMILY="unknown"
        OS_NAME="Unknown Linux"
    fi
    
    export OS_ID OS_VERSION OS_NAME OS_FAMILY
}

# Detect package manager
detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt-get install -y"
        PKG_UPDATE="apt-get update"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf check-update"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
        PKG_UPDATE="yum check-update"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Sy"
    elif command -v emerge &>/dev/null; then
        PKG_MANAGER="emerge"
        PKG_INSTALL="emerge"
        PKG_UPDATE="emerge --sync"
    else
        PKG_MANAGER="unknown"
        PKG_INSTALL=""
        PKG_UPDATE=""
    fi
    
    export PKG_MANAGER PKG_INSTALL PKG_UPDATE
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Check if sudo is available and user has sudo access
has_sudo() {
    if command_exists sudo; then
        sudo -n true 2>/dev/null
        return $?
    fi
    return 1
}

# Run command with sudo if not root
run_as_root() {
    if is_root; then
        "$@"
    elif has_sudo; then
        sudo "$@"
    else
        log_error "This operation requires sudo access"
        return 1
    fi
}

# Check for required commands
check_prerequisites() {
    local missing=()
    local required=("$@")
    
    for cmd in "${required[@]}"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Get package names for different distributions
get_package_names() {
    local tool="$1"
    local packages=""
    
    case "$tool" in
        build-essential)
            case "$OS_FAMILY" in
                debian)
                    packages="build-essential"
                    ;;
                rhel)
                    packages="gcc gcc-c++ make"
                    ;;
                arch)
                    packages="base-devel"
                    ;;
                gentoo)
                    packages="" # Already part of system
                    ;;
            esac
            ;;
        git|curl|make|wget)
            packages="$tool"
            ;;
        python3-pip)
            case "$OS_FAMILY" in
                debian)
                    packages="python3-pip"
                    ;;
                rhel)
                    packages="python3-pip"
                    ;;
                arch)
                    packages="python-pip"
                    ;;
                gentoo)
                    packages="dev-python/pip"
                    ;;
            esac
            ;;
        cargo|rust)
            case "$OS_FAMILY" in
                debian)
                    packages="cargo"
                    ;;
                rhel)
                    packages="cargo"
                    ;;
                arch)
                    packages="rust"
                    ;;
                gentoo)
                    packages="dev-lang/rust"
                    ;;
            esac
            ;;
    esac
    
    echo "$packages"
}

# Initialize - detect OS and package manager
init_common() {
    detect_os
    detect_package_manager
    
    log_info "Detected OS: $OS_NAME ($OS_ID)"
    log_info "OS Family: $OS_FAMILY"
    log_info "Package Manager: $PKG_MANAGER"
}

