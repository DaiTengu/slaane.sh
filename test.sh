#!/usr/bin/env bash
# Test script for portable bash environment
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
    if command -v gcc &>/dev/null || command -v cc &>/dev/null; then
        echo -e "${GREEN}✓${NC} C compiler found"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} C compiler NOT found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
    
    # Test bash-it
    echo -e "${YELLOW}Testing bash-it...${NC}"
    test_dir_exists "$HOME/.bash_it" "bash-it directory" || true
    test_file_exists "$HOME/.bash_it/bash_it.sh" "bash-it main script" || true
    
    # Test some bash-it components
    if [[ -d "$HOME/.bash_it" ]]; then
        test_bash_it_component "plugin" "base" || true
        test_bash_it_component "plugin" "git" || true
        test_bash_it_component "alias" "general" || true
    fi
    echo ""
    
    # Test ble.sh
    echo -e "${YELLOW}Testing ble.sh...${NC}"
    test_file_exists "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" "ble.sh installed" || true
    test_file_exists "$HOME/.blerc" "ble.sh config" || true
    echo ""
    
    # Test fzf
    echo -e "${YELLOW}Testing fzf...${NC}"
    test_dir_exists "$HOME/.fzf" "fzf directory" || true
    test_command_exists "fzf" "fzf command" "true" || true
    echo ""
    
    # Test zoxide
    echo -e "${YELLOW}Testing zoxide...${NC}"
    test_command_exists "zoxide" "zoxide command" || true
    echo ""
    
    # Test pyenv
    echo -e "${YELLOW}Testing pyenv...${NC}"
    test_dir_exists "$HOME/.pyenv" "pyenv directory" || true
    if [[ -d "$HOME/.pyenv" ]]; then
        test_file_exists "$HOME/.pyenv/bin/pyenv" "pyenv binary" || true
        test_dir_exists "$HOME/.pyenv/plugins/pyenv-virtualenv" "pyenv-virtualenv plugin" || true
    fi
    echo ""
    
    # Test goenv
    echo -e "${YELLOW}Testing goenv...${NC}"
    test_dir_exists "$HOME/.goenv" "goenv directory" || true
    if [[ -d "$HOME/.goenv" ]]; then
        test_file_exists "$HOME/.goenv/bin/goenv" "goenv binary" || true
    fi
    echo ""
    
    # Test thefuck
    echo -e "${YELLOW}Testing thefuck...${NC}"
    test_command_exists "thefuck" "thefuck command" || true
    echo ""
    
    # Test nano syntax highlighting
    echo -e "${YELLOW}Testing nano syntax highlighting...${NC}"
    test_dir_exists "$HOME/.nano" "nano syntax directory" || true
    if [[ -d "$HOME/.nano" ]]; then
        local nanorc_count=$(find "$HOME/.nano" -name "*.nanorc" 2>/dev/null | wc -l)
        if [[ $nanorc_count -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} nano syntax files: $nanorc_count files found"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${YELLOW}⚠${NC} nano syntax directory exists but no .nanorc files found"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
    # Note: nano itself is optional, so we don't test for it
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
        
        if grep -q "PYENV_ROOT" "$HOME/.bashrc" || grep -q "pyenv" "$HOME/.bashrc"; then
            echo -e "${GREEN}✓${NC} .bashrc contains pyenv configuration"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗${NC} .bashrc missing pyenv configuration"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
    echo ""
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

