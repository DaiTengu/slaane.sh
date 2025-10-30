#!/usr/bin/env bash
# Docker-based testing for portable bash environment
# Tests installation across multiple Linux distributions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configurations
DISTRIBUTIONS=(
    "ubuntu:22.04"
    "ubuntu:20.04"
    "debian:12"
    "debian:11"
    "fedora:39"
    "fedora:38"
    "rockylinux:9"
    "rockylinux:8"
    "archlinux:latest"
)

INSTALL_MODES=(
    "default"
    "minimal"
    "skip-goenv"
    "with-bashhub"
)

# Parse arguments
DISTRO_FILTER=""
MODE_FILTER=""
INTERACTIVE=false

show_usage() {
    cat <<EOF
Docker-based testing for Portable Bash Environment

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --distro PATTERN    Test only distributions matching pattern
    -m, --mode MODE         Test only specific installation mode
    -i, --interactive       Run interactive shell in test container
    -l, --list              List available distributions and modes

Modes:
    default       - Full installation (all core components)
    minimal       - Minimal installation (bash-it, ble.sh, fzf only)
    skip-goenv    - Skip goenv installation
    with-bashhub  - Include bashhub installation

Examples:
    # Test on all distributions with default mode
    $0

    # Test only Ubuntu distributions
    $0 --distro ubuntu

    # Test minimal installation on Fedora
    $0 --distro fedora --mode minimal

    # Interactive shell in Ubuntu container
    $0 --distro ubuntu:22.04 --interactive

    # List available options
    $0 --list

EOF
}

list_options() {
    echo "Available distributions:"
    for distro in "${DISTRIBUTIONS[@]}"; do
        echo "  - $distro"
    done
    echo ""
    echo "Available modes:"
    for mode in "${INSTALL_MODES[@]}"; do
        echo "  - $mode"
    done
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                list_options
                exit 0
                ;;
            -d|--distro)
                DISTRO_FILTER="$2"
                shift 2
                ;;
            -m|--mode)
                MODE_FILTER="$2"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

get_install_command() {
    local mode="$1"
    
    case "$mode" in
        default)
            echo "./install.sh --install-prereqs"
            ;;
        minimal)
            echo "./install.sh --install-prereqs --minimal"
            ;;
        skip-goenv)
            echo "./install.sh --install-prereqs --skip=goenv"
            ;;
        with-bashhub)
            echo "./install.sh --install-prereqs --with-bashhub"
            ;;
        *)
            echo "./install.sh --install-prereqs"
            ;;
    esac
}

build_test_dockerfile() {
    local distro="$1"
    local mode="$2"
    local dockerfile="$SCRIPT_DIR/.test-dockerfile"
    
    local install_cmd=$(get_install_command "$mode")
    
    cat > "$dockerfile" <<EOF
FROM ${distro}

# Install sudo (required for some distros)
RUN if command -v apt-get > /dev/null; then \\
        apt-get update && apt-get install -y sudo; \\
    elif command -v dnf > /dev/null; then \\
        dnf install -y sudo; \\
    elif command -v yum > /dev/null; then \\
        yum install -y sudo; \\
    elif command -v pacman > /dev/null; then \\
        pacman -Sy --noconfirm sudo; \\
    fi

# Create test user with sudo access
RUN useradd -m -s /bin/bash testuser && \\
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy portable-bash-env to user's home
COPY --chown=testuser:testuser . /home/testuser/portable-bash-env

# Switch to test user
USER testuser
WORKDIR /home/testuser/portable-bash-env

# Run installation
RUN ${install_cmd}

# Run tests
RUN ./test.sh

# Default command
CMD ["/bin/bash"]
EOF
}

run_test() {
    local distro="$1"
    local mode="$2"
    local tag="portable-bash-test:${distro//:/_}-${mode}"
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Testing: $distro (mode: $mode)${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Build Dockerfile
    build_test_dockerfile "$distro" "$mode"
    
    # Build image
    echo -e "${YELLOW}Building Docker image...${NC}"
    if ! docker build -f "$SCRIPT_DIR/.test-dockerfile" -t "$tag" "$SCRIPT_DIR"; then
        echo -e "${RED}✗ Build failed for $distro ($mode)${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Build succeeded for $distro ($mode)${NC}"
    
    # Run container interactively if requested
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -e "${YELLOW}Starting interactive shell...${NC}"
        docker run --rm -it "$tag" /bin/bash
    fi
    
    # Clean up
    rm -f "$SCRIPT_DIR/.test-dockerfile"
    
    return 0
}

main() {
    parse_args "$@"
    
    # Check if Docker is available
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        echo "Please install Docker to run these tests"
        exit 1
    fi
    
    # Filter distributions
    local distros_to_test=()
    for distro in "${DISTRIBUTIONS[@]}"; do
        if [[ -z "$DISTRO_FILTER" ]] || [[ "$distro" == *"$DISTRO_FILTER"* ]]; then
            distros_to_test+=("$distro")
        fi
    done
    
    # Filter modes
    local modes_to_test=()
    for mode in "${INSTALL_MODES[@]}"; do
        if [[ -z "$MODE_FILTER" ]] || [[ "$mode" == "$MODE_FILTER" ]]; then
            modes_to_test+=("$mode")
        fi
    done
    
    if [[ ${#distros_to_test[@]} -eq 0 ]]; then
        echo -e "${RED}No distributions match filter: $DISTRO_FILTER${NC}"
        exit 1
    fi
    
    if [[ ${#modes_to_test[@]} -eq 0 ]]; then
        echo -e "${RED}No modes match filter: $MODE_FILTER${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Docker Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "Distributions: ${distros_to_test[*]}"
    echo "Modes: ${modes_to_test[*]}"
    echo ""
    
    local total=0
    local passed=0
    local failed=0
    
    # Run tests
    for distro in "${distros_to_test[@]}"; do
        for mode in "${modes_to_test[@]}"; do
            ((total++))
            if run_test "$distro" "$mode"; then
                ((passed++))
            else
                ((failed++))
            fi
            echo ""
        done
    done
    
    # Summary
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Suite Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total: $total"
    echo -e "${GREEN}Passed: $passed${NC}"
    echo -e "${RED}Failed: $failed${NC}"
    echo ""
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"

