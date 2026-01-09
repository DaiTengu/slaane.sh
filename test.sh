#!/usr/bin/env bash
# Simple test script for Slaane.sh
# Tests that modules are actually installed and functional

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0
CORE_FAILED=0

# Test helpers
check() {
    local name="$1"
    local condition="$2"
    
    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name"
        ((FAILED++))
    fi
}

check_core() {
    local name="$1"
    local condition="$2"
    
    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name (CORE)"
        ((FAILED++))
        ((CORE_FAILED++))
    fi
}

check_optional() {
    local name="$1"
    local condition="$2"
    
    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED++))
    else
        echo -e "${YELLOW}○${NC} $name (optional, skipped)"
        # Don't count as failure
    fi
}

# Add common paths
export PATH="$HOME/.local/bin:$HOME/.fzf/bin:$HOME/.pyenv/bin:$HOME/.goenv/bin:$PATH"

echo "========================================"
echo "Slaane.sh Test Suite"
echo "========================================"
echo ""

# ============================================================================
# Core Modules (must pass)
# ============================================================================
echo "--- Core Modules ---"

# bash-it
check_core "bash-it directory exists" "[[ -d '$HOME/.bash_it' ]]"
check_core "bash-it script exists" "[[ -f '$HOME/.bash_it/bash_it.sh' ]]"

# blesh  
check_core "blesh installed" "[[ -f '$HOME/.local/share/blesh/ble.sh' ]]"
check_core "blerc exists" "[[ -f '$HOME/.blerc' ]]"

# fzf
check_core "fzf directory exists" "[[ -d '$HOME/.fzf' ]]"
check_core "fzf binary works" "command -v fzf &>/dev/null && fzf --version &>/dev/null"

echo ""

# ============================================================================
# Default Modules (warnings only)
# ============================================================================
echo "--- Default Modules ---"

# pyenv
check "pyenv directory exists" "[[ -d '$HOME/.pyenv' ]]"
check "pyenv binary exists" "[[ -f '$HOME/.pyenv/bin/pyenv' ]]"

# goenv
check "goenv directory exists" "[[ -d '$HOME/.goenv' ]]"
check "goenv binary exists" "[[ -f '$HOME/.goenv/bin/goenv' ]]"

# zoxide
check "zoxide binary works" "command -v zoxide &>/dev/null"

# thefuck - optional, often fails on minimal systems
check_optional "thefuck binary" "command -v thefuck &>/dev/null"

# nano syntax
check "nano syntax dir exists" "[[ -d '$HOME/.nano' ]]"

echo ""

# ============================================================================
# Configuration
# ============================================================================
echo "--- Configuration ---"

check_core ".bashrc exists" "[[ -f '$HOME/.bashrc' ]]"
check_core ".bashrc contains bash-it" "grep -q 'bash_it' '$HOME/.bashrc' 2>/dev/null"
check "slaane.sh symlink exists" "[[ -L '$HOME/.local/bin/slaane.sh' ]]"

echo ""

# ============================================================================
# Functional Tests
# ============================================================================
echo "--- Functional Tests ---"

check_core "slaane.sh help works" "'$SCRIPT_DIR/slaane.sh' help &>/dev/null"
check_core "slaane.sh list works" "'$SCRIPT_DIR/slaane.sh' list &>/dev/null"

# Test bashrc can be sourced (in subshell to not affect current shell)
check_core "bashrc sources without error" "bash -c 'source ~/.bashrc' &>/dev/null"

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "========================================"
TOTAL=$((PASSED + FAILED))
echo "Results: $PASSED/$TOTAL passed"

if [[ $CORE_FAILED -gt 0 ]]; then
    echo -e "${RED}FAILED: $CORE_FAILED core test(s) failed${NC}"
    exit 1
elif [[ $FAILED -gt 0 ]]; then
    echo -e "${YELLOW}PASSED (with warnings): $FAILED non-critical failure(s)${NC}"
    exit 0
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
