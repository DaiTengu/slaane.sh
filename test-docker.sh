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
Docker-based testing for Slaane.sh

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
            echo "./slaane.sh install --install-prereqs"
            ;;
        minimal)
            echo "./slaane.sh install --install-prereqs --minimal"
            ;;
        skip-goenv)
            echo "./slaane.sh install --install-prereqs --skip=goenv"
            ;;
        with-bashhub)
            echo "./slaane.sh install --install-prereqs --with-bashhub"
            ;;
        *)
            echo "./slaane.sh install --install-prereqs"
            ;;
    esac
}

# Update README.md with test results
update_readme_with_results() {
    local readme_file="$SCRIPT_DIR/README.md"
    local temp_readme=$(mktemp)
    
    if [[ ! -f "$readme_file" ]]; then
        echo -e "${YELLOW}Warning: README.md not found, skipping update${NC}"
        return 1
    fi
    
    # Map distribution names for display
    declare -A distro_map=(
        ["rockylinux 9"]="Rocky Linux 9"
        ["rockylinux:9"]="Rocky Linux 9"
        ["rockylinux 8"]="Rocky Linux 8"
        ["rockylinux:8"]="Rocky Linux 8"
        ["ubuntu 22.04"]="Ubuntu 22.04"
        ["ubuntu:22.04"]="Ubuntu 22.04"
        ["ubuntu 20.04"]="Ubuntu 20.04"
        ["ubuntu:20.04"]="Ubuntu 20.04"
        ["debian 12"]="Debian 12"
        ["debian:12"]="Debian 12"
        ["debian 11"]="Debian 11"
        ["debian:11"]="Debian 11"
        ["fedora 39"]="Fedora 39"
        ["fedora:39"]="Fedora 39"
        ["fedora 38"]="Fedora 38"
        ["fedora:38"]="Fedora 38"
        ["archlinux latest"]="Arch Linux"
        ["archlinux:latest"]="Arch Linux"
    )
    
    # Read test results and build replacement text
    local results_section=""
    local distro_count=0
    local results_array=()
    
    while IFS='|' read -r distro passed failed; do
        [[ -z "$distro" ]] && continue
        
        # Normalize distro name (handle both : and space formats)
        local distro_normalized=$(echo "$distro" | sed 's/:/ /g')
        
        # Look up in map, trying both normalized and original formats
        local distro_name="${distro_map[$distro]:-${distro_map[$distro_normalized]:-}}"
        
        # If not found in map, prettify the normalized name
        if [[ -z "$distro_name" ]]; then
            # Capitalize first letter of each word
            distro_name=$(echo "$distro_normalized" | sed 's/\b\(.\)/\u\1/g')
            # Fix common names
            distro_name=$(echo "$distro_name" | sed 's/Rockylinux/Rocky Linux/g; s/Archlinux/Arch Linux/g')
        fi
        
        local total_tests=$((passed + failed))
        
        if [[ -n "$passed" ]] && [[ -n "$failed" ]] && [[ "$passed" =~ ^[0-9]+$ ]] && [[ "$failed" =~ ^[0-9]+$ ]]; then
            results_array+=("$distro_name|$passed|$total_tests")
            distro_count=$((distro_count + 1))
        fi
    done < "$SCRIPT_DIR/.test-results.tmp"
    
    # Sort results by distribution name (for consistency)
    IFS=$'\n' results_array=($(printf '%s\n' "${results_array[@]}" | sort))
    unset IFS
    
    # Build the results section
    results_section="Tested and verified across multiple distributions:\n"
    for result in "${results_array[@]}"; do
        IFS='|' read -r distro_name passed total <<< "$result"
        results_section+="- ✅ $distro_name ($passed/$total tests)\n"
    done
    unset IFS
    
    # Replace the test results section in README
    local in_section=false
    local section_started=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if we're entering the test results section
        if [[ "$line" =~ ^Tested\ and\ verified ]]; then
            in_section=true
            section_started=true
            # Output the new section (header + list)
            echo -e "$results_section"
            continue
        fi
        
        # Skip lines until we hit the next section
        if [[ "$in_section" == "true" ]]; then
            # Skip old list items (lines starting with - ✅)
            if [[ "$line" =~ ^-[[:space:]]*✅ ]]; then
                continue
            # Stop skipping when we hit a new section (##)
            elif [[ "$line" =~ ^## ]]; then
                in_section=false
                section_started=false
                echo "$line"
            # Stop skipping when we hit an empty line after we've output our section
            elif [[ "$line" =~ ^[[:space:]]*$ ]] && [[ "$section_started" == "true" ]]; then
                in_section=false
                section_started=false
                echo "$line"
            # Skip empty lines and other content within the section
            else
                continue
            fi
        else
            echo "$line"
        fi
    done < "$readme_file" > "$temp_readme"
    
    mv "$temp_readme" "$readme_file"
    echo -e "${GREEN}✓ Updated README.md with test results${NC}"
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

# Copy slaane.sh to user's home
COPY --chown=testuser:testuser . /home/testuser/slaane.sh

# Switch to test user
USER testuser
WORKDIR /home/testuser/slaane.sh

# Run installation
RUN ${install_cmd}

# Run tests (pass distro name for results tracking)
RUN DISTRO_NAME="${distro}" TEST_UNINSTALL=true ./test.sh || true

# Copy results file to a known location
RUN if [ -f /home/testuser/slaane.sh/.test-results.tmp ]; then cat /home/testuser/slaane.sh/.test-results.tmp; fi || true

# Default command
CMD ["/bin/bash"]
EOF
}

run_test() {
    local distro="$1"
    local mode="$2"
    local tag="slaane-test:${distro//:/_}-${mode}"
    
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
    
    # Capture build output to extract test results
    local build_output=$(docker build $build_args -f "$SCRIPT_DIR/.test-dockerfile" -t "$tag" "$SCRIPT_DIR" 2>&1)
    local build_result=$?
    
    if [[ $build_result -ne 0 ]]; then
        echo "$build_output"
        echo -e "${RED}✗ Build failed for $distro ($mode)${NC}"
        return 1
    fi
    
    echo "$build_output" | grep -v "^Sending build context" | grep -v "^Step" | grep -v "^--->" | grep -v "^Removed intermediate container" | grep -v "^Successfully built" | grep -v "^Successfully tagged" | tail -50
    
    echo -e "${GREEN}✓ Build succeeded for $distro ($mode)${NC}"
    
    # Extract test results from .test-results.tmp that was written by test.sh
    # The results are printed in the build output (format: distro:version|passed|failed)
    # Example: "rockylinux:9|23|1"
    local results_line=$(echo "$build_output" | grep -E "\|[0-9]+\|[0-9]+$" | grep -v "^-->" | tail -1)
    
    if [[ -n "$results_line" ]] && [[ "$results_line" =~ \| ]]; then
        # Clean up the line (remove any leading/trailing whitespace)
        results_line=$(echo "$results_line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Extract the pattern (distro:version|passed|failed) from the line
        local pattern=$(echo "$results_line" | grep -oE "[^|]+\|[0-9]+\|[0-9]+" | head -1)
        
        if [[ -n "$pattern" ]]; then
            local distro_raw=$(echo "$pattern" | cut -d'|' -f1)
            local distro_clean=$(echo "$distro_raw" | sed 's/:/ /g')
            local passed_count=$(echo "$pattern" | cut -d'|' -f2)
            local failed_count=$(echo "$pattern" | cut -d'|' -f3)
            
            if [[ -n "$passed_count" ]] && [[ "$passed_count" =~ ^[0-9]+$ ]] && [[ -n "$failed_count" ]] && [[ "$failed_count" =~ ^[0-9]+$ ]]; then
                echo "${distro_clean}|${passed_count}|${failed_count}" >> "$SCRIPT_DIR/.test-results.tmp"
            fi
        fi
    fi
    
    # Fallback: try to extract from test summary output if results file line wasn't found
    if [[ ! -s "$SCRIPT_DIR/.test-results.tmp" ]] || ! grep -q "$(echo "$distro" | sed 's/:/ /g')" "$SCRIPT_DIR/.test-results.tmp" 2>/dev/null; then
        local passed_count=$(echo "$build_output" | grep "Passed:" | grep -oE "[0-9]+" | tail -1)
        local failed_count=$(echo "$build_output" | grep "Failed:" | grep -oE "[0-9]+" | tail -1)
        if [[ -n "$passed_count" ]] && [[ "$passed_count" =~ ^[0-9]+$ ]] && [[ -n "$failed_count" ]] && [[ "$failed_count" =~ ^[0-9]+$ ]]; then
            local distro_clean=$(echo "$distro" | sed 's/:/ /g')
            echo "${distro_clean}|${passed_count}|${failed_count}" >> "$SCRIPT_DIR/.test-results.tmp"
        fi
    fi
    
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
    
    # Initialize test results file
    rm -f "$SCRIPT_DIR/.test-results.tmp"
    touch "$SCRIPT_DIR/.test-results.tmp"
    
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
    
    # Update README with test results if we have results
    if [[ -f "$SCRIPT_DIR/.test-results.tmp" ]] && [[ -s "$SCRIPT_DIR/.test-results.tmp" ]]; then
        update_readme_with_results
        rm -f "$SCRIPT_DIR/.test-results.tmp"
    fi
    
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

