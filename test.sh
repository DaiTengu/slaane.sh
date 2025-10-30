#!/usr/bin/env bash
# Test script for portable bash environment
# Can be run locally or inside Docker containers

set -e

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

# Test functions
test_command_exists() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $description: $cmd found"
        TEST_RESULTS+=("PASS: $description")
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description: $cmd NOT found"
        TEST_RESULTS+=("FAIL: $description")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $description: $file exists"
        TEST_RESULTS+=("PASS: $description")
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description: $file NOT found"
        TEST_RESULTS+=("FAIL: $description")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_dir_exists() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $description: $dir exists"
        TEST_RESULTS+=("PASS: $description")
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description: $dir NOT found"
        TEST_RESULTS+=("FAIL: $description")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_bash_it_component() {
    local type="$1"  # alias, plugin, or completion
    local name="$2"
    
    local enabled_dir="$HOME/.bash_it/enabled"
    
    if ls "$enabled_dir"/*"---${name}.${type}.bash" &>/dev/null; then
        echo -e "${GREEN}✓${NC} bash-it $type enabled: $name"
        TEST_RESULTS+=("PASS: bash-it $type $name")
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} bash-it $type NOT enabled: $name"
        TEST_RESULTS+=("FAIL: bash-it $type $name")
        ((TESTS_FAILED++))
        return 1
    fi
}

run_tests() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Testing Portable Bash Environment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Test prerequisites
    echo -e "${YELLOW}Testing Prerequisites...${NC}"
    test_command_exists "git" "Git installed"
    test_command_exists "curl" "Curl installed"
    test_command_exists "make" "Make installed"
    if command -v gcc &>/dev/null || command -v cc &>/dev/null; then
        echo -e "${GREEN}✓${NC} C compiler found"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} C compiler NOT found"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Test bash-it
    echo -e "${YELLOW}Testing bash-it...${NC}"
    test_dir_exists "$HOME/.bash_it" "bash-it directory"
    test_file_exists "$HOME/.bash_it/bash_it.sh" "bash-it main script"
    
    # Test some bash-it components
    if [[ -d "$HOME/.bash_it" ]]; then
        test_bash_it_component "plugin" "base"
        test_bash_it_component "plugin" "git"
        test_bash_it_component "alias" "general"
    fi
    echo ""
    
    # Test ble.sh
    echo -e "${YELLOW}Testing ble.sh...${NC}"
    test_file_exists "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" "ble.sh installed"
    test_file_exists "$HOME/.blerc" "ble.sh config"
    echo ""
    
    # Test fzf
    echo -e "${YELLOW}Testing fzf...${NC}"
    test_dir_exists "$HOME/.fzf" "fzf directory"
    test_command_exists "fzf" "fzf command"
    echo ""
    
    # Test zoxide
    echo -e "${YELLOW}Testing zoxide...${NC}"
    test_command_exists "zoxide" "zoxide command"
    echo ""
    
    # Test pyenv
    echo -e "${YELLOW}Testing pyenv...${NC}"
    test_dir_exists "$HOME/.pyenv" "pyenv directory"
    if [[ -d "$HOME/.pyenv" ]]; then
        test_file_exists "$HOME/.pyenv/bin/pyenv" "pyenv binary"
        test_dir_exists "$HOME/.pyenv/plugins/pyenv-virtualenv" "pyenv-virtualenv plugin"
    fi
    echo ""
    
    # Test goenv
    echo -e "${YELLOW}Testing goenv...${NC}"
    test_dir_exists "$HOME/.goenv" "goenv directory"
    if [[ -d "$HOME/.goenv" ]]; then
        test_file_exists "$HOME/.goenv/bin/goenv" "goenv binary"
    fi
    echo ""
    
    # Test thefuck
    echo -e "${YELLOW}Testing thefuck...${NC}"
    test_command_exists "thefuck" "thefuck command"
    echo ""
    
    # Test configuration files
    echo -e "${YELLOW}Testing configuration files...${NC}"
    test_file_exists "$HOME/.bashrc" ".bashrc exists"
    
    # Test bashrc content
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q "bash-it" "$HOME/.bashrc"; then
            echo -e "${GREEN}✓${NC} .bashrc contains bash-it configuration"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗${NC} .bashrc missing bash-it configuration"
            ((TESTS_FAILED++))
        fi
        
        if grep -q "PYENV_ROOT" "$HOME/.bashrc" || grep -q "pyenv" "$HOME/.bashrc"; then
            echo -e "${GREEN}✓${NC} .bashrc contains pyenv configuration"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗${NC} .bashrc missing pyenv configuration"
            ((TESTS_FAILED++))
        fi
    fi
    echo ""
    
    # Test PATH additions
    echo -e "${YELLOW}Testing PATH configuration...${NC}"
    
    # Source bashrc to get updated PATH
    if [[ -f "$HOME/.bashrc" ]]; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
    
    # Check if important directories are in PATH
    local path_items=("$HOME/.local/bin" "$HOME/.fzf/bin")
    for item in "${path_items[@]}"; do
        if [[ ":$PATH:" == *":$item:"* ]]; then
            echo -e "${GREEN}✓${NC} PATH contains: $item"
            ((TESTS_PASSED++))
        else
            echo -e "${YELLOW}!${NC} PATH missing: $item (may be added on next login)"
        fi
    done
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
    else
        echo -e "${RED}Some tests failed. See details above.${NC}"
        return 1
    fi
}

# Main
main() {
    run_tests
    show_summary
}

main "$@"

