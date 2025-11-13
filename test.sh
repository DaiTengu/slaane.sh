#!/usr/bin/env bash
# Test script for Slaane.sh
# Can be run locally or inside Docker containers

# Don't use set -e, we want to count failures not exit immediately

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_RESULTS=()
TESTS_PASSED=0
TESTS_FAILED=0
CRITICAL_FAILURES=0

# Source module API and handlers for testing
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/module-api.sh"
source "$SCRIPT_DIR/lib/module-handlers.sh"
source "$SCRIPT_DIR/lib/state-tracking.sh"

# Initialize
init_common

# Add common binary locations to PATH for testing
export PATH="$HOME/.local/bin:$HOME/.fzf/bin:$HOME/.pyenv/bin:$HOME/.goenv/bin:$HOME/.cargo/bin:$PATH"

# Test functions
test_command_exists() {
    local cmd="$1"
    local description="$2"
    local critical="${3:-false}"
    
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $description: $cmd found"
        TEST_RESULTS+=("PASS: $description")
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description: $cmd NOT found"
        TEST_RESULTS+=("FAIL: $description")
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [[ "$critical" == "true" ]]; then
            CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
        fi
        return 1
    fi
}

test_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $description: $file exists"
        TEST_RESULTS+=("PASS: $description")
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description: $file NOT found"
        TEST_RESULTS+=("FAIL: $description")
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_dir_exists() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $description: $dir exists"
        TEST_RESULTS+=("PASS: $description")
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description: $dir NOT found"
        TEST_RESULTS+=("FAIL: $description")
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_bash_it_component() {
    local type="$1"  # alias, plugin, or completion
    local name="$2"
    
    # Determine file extension (aliases uses plural, plugin/completion use singular)
    local file_ext=""
    case "$type" in
        alias)
            file_ext="aliases"
            ;;
        plugin)
            file_ext="plugin"
            ;;
        completion)
            file_ext="completion"
            ;;
        *)
            echo -e "${RED}✗${NC} bash-it $type NOT enabled: $name (unknown type)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
            ;;
    esac
    
    local enabled_dir="$HOME/.bash_it/enabled"
    
    if ls "$enabled_dir"/*"---${name}.${file_ext}.bash" &>/dev/null; then
        echo -e "${GREEN}✓${NC} bash-it $type enabled: $name"
        TEST_RESULTS+=("PASS: bash-it $type $name")
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} bash-it $type NOT enabled: $name"
        TEST_RESULTS+=("FAIL: bash-it $type $name")
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

run_tests() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Testing Slaane.sh${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Test prerequisites
    echo -e "${YELLOW}Testing Prerequisites...${NC}"
    test_command_exists "git" "Git installed" || true
    test_command_exists "curl" "Curl installed" || true
    test_command_exists "make" "Make installed" || true
    echo ""
    
    # Test module discovery
    echo -e "${YELLOW}Testing module discovery...${NC}"
    local discovered_modules=($(discover_modules))
    if [[ ${#discovered_modules[@]} -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Discovered ${#discovered_modules[@]} modules"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} No modules discovered"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
    fi
    echo ""
    
    # Test modules using generic test handler
    echo -e "${YELLOW}Testing installed modules...${NC}"
    local installed_modules=($(get_installed_modules))
    
    if [[ ${#installed_modules[@]} -eq 0 ]]; then
        # Test all discovered modules (they may not be installed yet)
        for module in "${discovered_modules[@]}"; do
            echo -e "${YELLOW}Testing module: $module${NC}"
            if test_module_generic "$module" 2>/dev/null; then
                echo ""
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo ""
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        done
    else
        # Test only installed modules
        for module in "${installed_modules[@]}"; do
            echo -e "${YELLOW}Testing module: $module${NC}"
            if test_module_generic "$module" 2>/dev/null; then
                echo ""
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo ""
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        done
    fi
    echo ""
    
    # Test configuration files
    echo -e "${YELLOW}Testing configuration files...${NC}"
    test_file_exists "$HOME/.bashrc" ".bashrc exists" || true
    
    # Test bashrc content
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q "bash-it" "$HOME/.bashrc"; then
            echo -e "${GREEN}✓${NC} .bashrc contains bash-it configuration"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗${NC} .bashrc missing bash-it configuration"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
    fi
    echo ""
    
    # Test slaane.sh master script
    echo -e "${YELLOW}Testing slaane.sh master script...${NC}"
    if [[ -f "$SCRIPT_DIR/slaane.sh" ]]; then
        echo -e "${GREEN}✓${NC} slaane.sh exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Test help command
        if "$SCRIPT_DIR/slaane.sh" help &>/dev/null; then
            echo -e "${GREEN}✓${NC} slaane.sh help works"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗${NC} slaane.sh help failed"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        # Test list command
        if "$SCRIPT_DIR/slaane.sh" list &>/dev/null; then
            echo -e "${GREEN}✓${NC} slaane.sh list works"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗${NC} slaane.sh list failed"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "${RED}✗${NC} slaane.sh NOT found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
    fi
    echo ""
    
    # Test local installation methods
    echo -e "${YELLOW}Testing local installation capabilities...${NC}"
    
    # Test zoxide binary download method
    if command -v zoxide &>/dev/null; then
        local zoxide_path=$(command -v zoxide)
        if [[ "$zoxide_path" == *".local/bin"* ]]; then
            echo -e "${GREEN}✓${NC} zoxide installed in user's .local/bin (no sudo)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${YELLOW}⚠${NC} zoxide found at: $zoxide_path (may be system-wide)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        fi
    fi
    
    # Test thefuck pip installation
    if command -v thefuck &>/dev/null; then
        local thefuck_path=$(command -v thefuck)
        if [[ "$thefuck_path" == *".local/bin"* ]] || [[ "$thefuck_path" == *".pyenv"* ]]; then
            echo -e "${GREEN}✓${NC} thefuck installed via pip (no sudo)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${YELLOW}⚠${NC} thefuck found at: $thefuck_path (may be system-wide)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        fi
    fi
    
    # Test fzf git clone method
    if command -v fzf &>/dev/null; then
        local fzf_path=$(command -v fzf)
        if [[ "$fzf_path" == *".fzf"* ]]; then
            echo -e "${GREEN}✓${NC} fzf installed via git clone in user directory"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${YELLOW}⚠${NC} fzf found at: $fzf_path"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        fi
    fi
    echo ""
    
    # Test uninstall functionality (always enabled, can disable with TEST_UNINSTALL=false)
    if [[ "${TEST_UNINSTALL:-true}" == "true" ]]; then
        echo -e "${YELLOW}Testing complete uninstall...${NC}"
        
        # Verify we have modules installed before uninstalling
        local installed_modules=($(get_installed_modules))
        if [[ ${#installed_modules[@]} -eq 0 ]]; then
            echo -e "${YELLOW}⚠${NC} No modules installed, skipping uninstall test"
            echo ""
            return 0
        fi
        
        echo -e "${YELLOW}Uninstalling all modules (including core modules)...${NC}"
        echo -e "${YELLOW}Testing complete purge (removes slaane.sh repository)...${NC}"
        
        # Uninstall with --purge (complete removal)
        if { echo "yes"; } | "$SCRIPT_DIR/slaane.sh" uninstall --purge &>/dev/null; then
            echo -e "${GREEN}✓${NC} Uninstall all command executed"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            
            # Verify all modules are uninstalled
            local remaining_modules=($(get_installed_modules))
            if [[ ${#remaining_modules[@]} -eq 0 ]]; then
                echo -e "${GREEN}✓${NC} All modules removed from tracking"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗${NC} Some modules still tracked: ${remaining_modules[*]}"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
            
            # Verify core module directories are gone
            local core_gone=true
            for module in bash-it blesh fzf; do
                if [[ "$module" == "bash-it" ]] && [[ -d "$HOME/.bash_it" ]]; then
                    echo -e "${RED}✗${NC} Core module $module directory still exists: $HOME/.bash_it"
                    core_gone=false
                    TESTS_FAILED=$((TESTS_FAILED + 1))
                elif [[ "$module" == "blesh" ]] && [[ -d "$HOME/.local/share/blesh" ]]; then
                    echo -e "${RED}✗${NC} Core module $module directory still exists: $HOME/.local/share/blesh"
                    core_gone=false
                    TESTS_FAILED=$((TESTS_FAILED + 1))
                elif [[ "$module" == "fzf" ]] && [[ -d "$HOME/.fzf" ]]; then
                    echo -e "${RED}✗${NC} Core module $module directory still exists: $HOME/.fzf"
                    core_gone=false
                    TESTS_FAILED=$((TESTS_FAILED + 1))
                fi
            done
            
            if [[ "$core_gone" == "true" ]]; then
                echo -e "${GREEN}✓${NC} Core module directories removed"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            fi
            
            # Verify .bashrc was restored
            if [[ -f "$HOME/.bashrc.pre-slaanesh" ]]; then
                # Check if .bashrc was restored (should not contain slaane.sh references)
                if ! grep -q "slaane.sh" "$HOME/.bashrc" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} .bashrc restored (no slaane.sh references)"
                    TESTS_PASSED=$((TESTS_PASSED + 1))
                else
                    echo -e "${RED}✗${NC} .bashrc still contains slaane.sh references"
                    TESTS_FAILED=$((TESTS_FAILED + 1))
                fi
            else
                echo -e "${YELLOW}⚠${NC} .bashrc.pre-slaanesh backup not found (may have been clean install)"
            fi
            
            # Verify slaane.sh symlink is removed
            if [[ ! -L "$HOME/.local/bin/slaane.sh" ]]; then
                echo -e "${GREEN}✓${NC} slaane.sh symlink removed from PATH"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗${NC} slaane.sh symlink still exists: $HOME/.local/bin/slaane.sh"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
            
            # Verify complete purge - state directory and backup should be removed
            if [[ ! -d "$HOME/.slaane.sh" ]]; then
                echo -e "${GREEN}✓${NC} State tracking directory removed"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗${NC} State tracking directory still exists: $HOME/.slaane.sh"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
            
            if [[ ! -f "$HOME/.bashrc.pre-slaanesh" ]]; then
                echo -e "${GREEN}✓${NC} Backup .bashrc removed"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗${NC} Backup .bashrc still exists"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
            
            # Verify slaane.sh repository is removed
            if [[ ! -d "$SCRIPT_DIR" ]]; then
                echo -e "${GREEN}✓${NC} slaane.sh repository completely removed"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗${NC} slaane.sh repository still exists: $SCRIPT_DIR"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
            
        else
            echo -e "${RED}✗${NC} Uninstall all command failed"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        echo ""
    fi
}

show_summary() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    
    # Write results to file for README update (if DISTRO_NAME is set)
    if [[ "${TEST_UNINSTALL:-true}" == "true" ]] && [[ -n "${DISTRO_NAME:-}" ]]; then
        local results_file="${SCRIPT_DIR:-/tmp}/.test-results.tmp"
        echo "${DISTRO_NAME}|${TESTS_PASSED}|${TESTS_FAILED}" >> "$results_file"
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        return 0
    elif [[ $CRITICAL_FAILURES -eq 0 ]]; then
        echo -e "${YELLOW}Some optional tests failed, but core functionality works.${NC}"
        return 0
    else
        echo -e "${RED}Critical tests failed. See details above.${NC}"
        return 1
    fi
}

# Main
main() {
    run_tests
    show_summary
}

main "$@"

