#!/usr/bin/env bash
# Docker-based testing for Slaane.sh
# Simple, focused testing across distributions

set -u  # Don't use set -e, arithmetic can return falsy values

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Available distributions (using latest available tags from Docker Hub)
declare -A DISTROS=(
    ["rocky9"]="rockylinux:9"
    ["rocky8"]="rockylinux:8"
    ["ubuntu22"]="ubuntu:22.04"
    ["ubuntu20"]="ubuntu:20.04"
    ["debian12"]="debian:12"
    ["debian11"]="debian:11"
    ["fedora39"]="fedora:39"
    ["fedora38"]="fedora:38"
    ["arch"]="archlinux:latest"
)

# Parse args
DISTRO_FILTER="${1:-}"
INTERACTIVE=false

show_help() {
    cat <<EOF
Usage: $0 [distro] [--interactive]

Distros: ${!DISTROS[*]}

Examples:
    $0                  # Test all distros
    $0 rocky9           # Test Rocky 9 only
    $0 ubuntu22 -i      # Interactive shell in Ubuntu 22.04
EOF
}

case "$DISTRO_FILTER" in
    -h|--help) show_help; exit 0 ;;
    -i|--interactive) INTERACTIVE=true; DISTRO_FILTER="${2:-}" ;;
esac

[[ "${2:-}" == "-i" || "${2:-}" == "--interactive" ]] && INTERACTIVE=true

run_test() {
    local name="$1"
    local image="$2"
    
    echo -e "${BLUE}========================================"
    echo -e "Testing: $name ($image)"
    echo -e "========================================${NC}"
    
    # Create Dockerfile
    local dockerfile=$(mktemp)
    cat > "$dockerfile" <<EOF
FROM $image

# Install sudo and container-specific packages (not needed on real systems)
# procps-ng: provides ps (needed by blesh)
# glibc-langpack-en: provides locale (RHEL family)
RUN if command -v apt-get > /dev/null; then \\
        apt-get update && apt-get install -y sudo locales && \\
        locale-gen en_US.UTF-8; \\
    elif command -v dnf > /dev/null; then \\
        dnf install -y sudo procps-ng glibc-langpack-en; \\
    elif command -v yum > /dev/null; then \\
        yum install -y sudo procps-ng glibc-langpack-en; \\
    elif command -v pacman > /dev/null; then \\
        pacman -Sy --noconfirm sudo procps; \\
    fi

# Set locale (blesh complains without it)
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create test user
RUN useradd -m -s /bin/bash testuser && \\
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy repo
COPY --chown=testuser:testuser . /home/testuser/slaane.sh

USER testuser
WORKDIR /home/testuser/slaane.sh

# Install
RUN ./slaane.sh install --install-prereqs

# Test
RUN ./test.sh

CMD ["/bin/bash"]
EOF

    local tag="slaane-test:${name}"
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        # Build without running tests, then drop into shell
        local dockerfile_interactive=$(mktemp)
        cat > "$dockerfile_interactive" <<EOF
FROM $image
RUN if command -v apt-get > /dev/null; then \\
        apt-get update && apt-get install -y sudo locales && locale-gen en_US.UTF-8; \\
    elif command -v dnf > /dev/null; then dnf install -y sudo procps-ng glibc-langpack-en; \\
    elif command -v yum > /dev/null; then yum install -y sudo procps-ng glibc-langpack-en; \\
    elif command -v pacman > /dev/null; then pacman -Sy --noconfirm sudo procps; fi
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN useradd -m -s /bin/bash testuser && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY --chown=testuser:testuser . /home/testuser/slaane.sh
USER testuser
WORKDIR /home/testuser/slaane.sh
RUN ./slaane.sh install --install-prereqs
CMD ["/bin/bash"]
EOF
        docker build -f "$dockerfile_interactive" -t "$tag" "$SCRIPT_DIR" && \
        docker run --rm -it "$tag"
        rm -f "$dockerfile_interactive"
        return $?
    fi
    
    # Build and run
    if docker build -f "$dockerfile" -t "$tag" "$SCRIPT_DIR"; then
        echo -e "${GREEN}✓ $name passed${NC}"
        rm -f "$dockerfile"
        return 0
    else
        echo -e "${RED}✗ $name failed${NC}"
        rm -f "$dockerfile"
        return 1
    fi
}

main() {
    # Check Docker
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Error: Docker not installed${NC}"
        exit 1
    fi
    
    local passed=0
    local failed=0
    local distros_to_test=()
    
    # Filter distros
    if [[ -n "$DISTRO_FILTER" ]]; then
        if [[ -n "${DISTROS[$DISTRO_FILTER]:-}" ]]; then
            distros_to_test=("$DISTRO_FILTER")
        else
            echo -e "${RED}Unknown distro: $DISTRO_FILTER${NC}"
            echo "Available: ${!DISTROS[*]}"
            exit 1
        fi
    else
        distros_to_test=("${!DISTROS[@]}")
    fi
    
    # Run tests
    for name in "${distros_to_test[@]}"; do
        if run_test "$name" "${DISTROS[$name]}"; then
            ((passed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    # Summary
    echo "========================================"
    echo "Summary: $passed passed, $failed failed"
    echo "========================================"
    
    [[ $failed -eq 0 ]]
}

main "$@"
