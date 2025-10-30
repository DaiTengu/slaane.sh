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

ALL_INSTALL_MODES=(
    "default"
    "minimal"
    "skip-goenv"
    "with-bashhub"
)

# Default to only testing "default" mode unless --all-modes or --mode specified
DEFAULT_MODE="default"

# Parse arguments
DISTRO_FILTER=""
MODE_FILTER=""
INTERACTIVE=false
ALL_MODES=false

show_usage() {
    cat <<EOF
Docker-based testing for Portable Bash Environment

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --distro PATTERN    Test only distributions matching pattern
    -m, --mode MODE         Test only specific installation mode
    -a, --all-modes         Test all installation modes (default tests only 'default' mode)
    -i, --interactive       Run interactive shell in test container
    -l, --list              List available distributions and modes

Modes:
    default       - Full installation (all core components)
    minimal       - Minimal installation (bash-it, ble.sh, fzf only)
    skip-goenv    - Skip goenv installation
    with-bashhub  - Include bashhub installation

Examples:
    # Test all distributions with default mode
    $0

    # Test all distributions with all modes (slow!)
    $0 --all-modes

    # Test only Ubuntu with default mode
    $0 --distro ubuntu

    # Test Ubuntu with all installation modes
    $0 --distro ubuntu --all-modes

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
    for mode in "${ALL_INSTALL_MODES[@]}"; do
        echo "  - $mode"
    done
    echo ""
    echo "Note: By default, only 'default' mode is tested."
    echo "      Use --all-modes to test all modes, or --mode to specify one."
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
            -a|--all-modes)
                ALL_MODES=true
                shift
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
    local build_args=""
    if [[ "${NO_CACHE:-}" == "true" ]]; then
        build_args="--no-cache"
    fi
    if ! docker build $build_args -f "$SCRIPT_DIR/.test-dockerfile" -t "$tag" "$SCRIPT_DIR"; then
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
    if [[ -n "$MODE_FILTER" ]]; then
        # User specified a specific mode
        modes_to_test+=("$MODE_FILTER")
    elif [[ "$ALL_MODES" == "true" ]]; then
        # User wants all modes
        modes_to_test=("${ALL_INSTALL_MODES[@]}")
    else
        # Default: only test "default" mode
        modes_to_test+=("$DEFAULT_MODE")
    fi
    
    if [[ ${#distros_to_test[@]} -eq 0 ]]; then
        echo -e "${RED}No distributions match filter: $DISTRO_FILTER${NC}"
        exit 1
    fi
    
    # Validate mode filter if specified
    if [[ -n "$MODE_FILTER" ]]; then
        local valid_mode=false
        for mode in "${ALL_INSTALL_MODES[@]}"; do
            if [[ "$MODE_FILTER" == "$mode" ]]; then
                valid_mode=true
                break
            fi
        done
        if [[ "$valid_mode" == "false" ]]; then
            echo -e "${RED}Invalid mode: $MODE_FILTER${NC}"
            echo "Valid modes: ${ALL_INSTALL_MODES[*]}"
            exit 1
        fi
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
            total=$((total + 1))
            if run_test "$distro" "$mode"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
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

