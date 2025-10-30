# Testing Guide

This document describes how to test the Slaane.sh installer.

## Quick Testing

### Local Testing

Test on your current system:

```bash
# Run basic tests
./test.sh
```

This will verify:
- Prerequisites are installed
- All components are present
- Configuration files exist
- bash-it components are enabled
- PATH is configured correctly

### Manual Installation Test

Test the full installation process:

```bash
# In a temporary directory or VM
./install.sh --install-prereqs

# Then verify
./test.sh
```

## Docker-Based Testing

Test across multiple Linux distributions using Docker.

### Prerequisites

Install Docker:

```bash
# Ubuntu/Debian
sudo apt-get install docker.io

# RHEL/Fedora
sudo dnf install docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

### Basic Docker Tests

**Important:** By default, tests run with only the `default` installation mode. Use `--all-modes` to test all modes.

```bash
# Test all distributions with default mode (recommended for quick testing)
./test-docker.sh

# Test all distributions with ALL modes (very slow!)
./test-docker.sh --all-modes

# Test specific distribution with default mode
./test-docker.sh --distro ubuntu
./test-docker.sh --distro fedora
./test-docker.sh --distro rockylinux

# Test specific distribution with ALL modes
./test-docker.sh --distro ubuntu --all-modes

# Test specific version with default mode
./test-docker.sh --distro ubuntu:22.04

# Test Rocky Linux 9 specifically
./test-docker.sh --distro rockylinux:9
```

### Test Different Installation Modes

**Note:** These test specific modes across all distributions. For single distro + mode, see Combined Tests below.

```bash
# Test minimal installation on all distros
./test-docker.sh --mode minimal

# Test with bashhub on all distros
./test-docker.sh --mode with-bashhub

# Test skipping components on all distros
./test-docker.sh --mode skip-goenv

# Test all modes on all distros (VERY slow - not recommended)
./test-docker.sh --all-modes
```

### Combined Tests

```bash
# Test Ubuntu with minimal installation (single test)
./test-docker.sh --distro ubuntu --mode minimal

# Test Fedora 39 with default installation (single test)
./test-docker.sh --distro fedora:39

# Test Rocky Linux 9 with all modes (4 tests)
./test-docker.sh --distro rockylinux:9 --all-modes

# Test Debian with skip-goenv mode (single test)
./test-docker.sh --distro debian --mode skip-goenv
```

### Interactive Testing

Drop into a shell inside a test container:

```bash
# Open interactive shell in Ubuntu test container
./test-docker.sh --distro ubuntu:22.04 --interactive

# Inside the container, you can:
cd ~/portable-bash-env
source ~/.bashrc
bash-it show plugins
fzf --version
zoxide --version
```

### List Available Options

```bash
./test-docker.sh --list
```

## Tested Distributions

The following distributions are tested:

### Debian Family
- Ubuntu 22.04 (Jammy)
- Ubuntu 20.04 (Focal)
- Debian 12 (Bookworm)
- Debian 11 (Bullseye)

### Red Hat Family
- Fedora 39
- Fedora 38
- Rocky Linux 9
- Rocky Linux 8

### Other
- Arch Linux (latest)

## Test Scenarios

### 1. Quick Single Distribution Test (Recommended)

Test one distribution with default mode (fastest):

```bash
# Test Rocky Linux 9 only
./test-docker.sh --distro rockylinux:9

# Test Ubuntu 22.04 only
./test-docker.sh --distro ubuntu:22.04
```

### 2. Default Installation on All Distros

Tests all distributions with default mode (all core components):

```bash
./test-docker.sh
```

Components tested:
- bash-it
- ble.sh
- fzf
- zoxide
- pyenv
- goenv
- thefuck

### 3. Minimal Installation

Tests minimal setup (bash-it, ble.sh, fzf only):

```bash
# Minimal on all distros
./test-docker.sh --mode minimal

# Minimal on specific distro
./test-docker.sh --distro ubuntu --mode minimal
```

### 4. Component Skipping

Tests installation with some components skipped:

```bash
# Skip goenv on all distros
./test-docker.sh --mode skip-goenv

# Skip goenv on Rocky Linux only
./test-docker.sh --distro rockylinux --mode skip-goenv
```

### 5. With Optional Components

Tests with bashhub included:

```bash
# With bashhub on all distros
./test-docker.sh --mode with-bashhub

# With bashhub on Fedora only
./test-docker.sh --distro fedora --mode with-bashhub
```

### 6. All Modes (Comprehensive but Slow)

Tests all installation modes:

```bash
# All modes on all distros (36 tests - very slow!)
./test-docker.sh --all-modes

# All modes on Ubuntu only (4 tests - moderate)
./test-docker.sh --distro ubuntu --all-modes

# All modes on Rocky Linux 9 only (4 tests)
./test-docker.sh --distro rockylinux:9 --all-modes
```

## Manual Testing Checklist

If running tests manually without Docker:

### Prerequisites
- [ ] git is installed
- [ ] curl is installed
- [ ] make is installed
- [ ] C compiler (gcc) is installed

### Installation
- [ ] Installer runs without errors
- [ ] All modules complete successfully
- [ ] Configuration files are created

### bash-it
- [ ] `~/.bash_it` directory exists
- [ ] bash-it loads without errors
- [ ] Enabled plugins are active
- [ ] Enabled aliases work
- [ ] Completions are available

### ble.sh
- [ ] ble.sh is installed in `~/.local/share/blesh`
- [ ] `~/.blerc` configuration exists
- [ ] Syntax highlighting works
- [ ] Auto-suggestions appear
- [ ] fzf integration works (Ctrl+R, Ctrl+T)

### fzf
- [ ] `fzf` command is available
- [ ] `~/.fzf` directory exists
- [ ] Ctrl+R searches history
- [ ] Ctrl+T finds files
- [ ] Alt+C changes directory

### zoxide
- [ ] `zoxide` command is available
- [ ] `z` command works (smart cd)
- [ ] Directory tracking functions

### pyenv
- [ ] `~/.pyenv` directory exists
- [ ] `pyenv` command works
- [ ] pyenv-virtualenv plugin installed
- [ ] Can list Python versions: `pyenv install --list`

### goenv
- [ ] `~/.goenv` directory exists
- [ ] `goenv` command works
- [ ] Can list Go versions: `goenv install --list`

### thefuck
- [ ] `thefuck` command is available
- [ ] `fuck` alias works
- [ ] Corrects typos properly

### Configuration
- [ ] `~/.bashrc` loads without errors
- [ ] PATH includes necessary directories
- [ ] All tools are in PATH
- [ ] Environment variables are set correctly

## Continuous Integration

For CI/CD pipelines, use the Docker tests:

```yaml
# Example GitHub Actions workflow
name: Test Portable Bash Environment

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Docker tests
        run: ./test-docker.sh
```

## Troubleshooting Tests

### Docker Permission Errors

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Then logout and login, or:
newgrp docker
```

### Container Build Failures

```bash
# Clean Docker cache
docker system prune -a

# Retry with specific distro
./test-docker.sh --distro ubuntu:22.04
```

### Test Failures

If tests fail:

1. Check the test output for specific failures
2. Run interactively to investigate:
   ```bash
   ./test-docker.sh --distro ubuntu --interactive
   ```
3. Inside the container:
   ```bash
   cd ~/portable-bash-env
   ./test.sh  # Run tests again
   cat ~/.bashrc  # Check configuration
   bash-it show plugins  # Check bash-it status
   ```

### Slow Tests

Docker tests can be slow. To speed up:

```bash
# Test only one distribution
./test-docker.sh --distro ubuntu:22.04 --mode default

# Or test locally instead of Docker
./install.sh --install-prereqs
./test.sh
```

## Adding New Tests

To add new tests to `test.sh`:

```bash
# Add a new test function
test_my_new_feature() {
    local description="My new feature"
    
    if [[ some_condition ]]; then
        echo -e "${GREEN}✓${NC} $description works"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description failed"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Call it in run_tests()
run_tests() {
    # ... existing tests ...
    test_my_new_feature
}
```

## Performance Testing

Test installation time on different systems:

```bash
time ./install.sh --install-prereqs
```

Expected times:
- **Ubuntu/Debian**: 2-5 minutes
- **Fedora/RHEL**: 3-6 minutes
- **Arch**: 2-4 minutes

Times vary based on:
- Network speed (cloning repos)
- CPU speed (building components)
- Disk speed (I/O operations)

## Security Testing

Verify the installer doesn't require unnecessary permissions:

```bash
# Should work without root/sudo (except --install-prereqs)
./install.sh

# Should NOT run if prerequisites missing (graceful failure)
# Manually remove a prerequisite and test
```

## Regression Testing

After making changes:

1. Run full test suite:
   ```bash
   ./test-docker.sh
   ```

2. Test on at least 3 distributions:
   - Debian-based (Ubuntu)
   - RHEL-based (Rocky/Fedora)
   - Other (Arch)

3. Test different installation modes:
   - Default
   - Minimal
   - With component skipping

## Test Matrix

### Default Behavior (Fast)

By default, tests run only `default` mode on selected distros:

| Distribution | Tests Run |
|-------------|-----------|
| All (no filter) | 9 tests (9 distros × 1 mode) |
| `--distro ubuntu` | 2 tests (ubuntu:22.04, 20.04 × 1 mode) |
| `--distro ubuntu:22.04` | 1 test (1 distro × 1 mode) |

### With --all-modes (Slow)

Tests all 4 modes on selected distros:

| Distribution | Tests Run |
|-------------|-----------|
| All with --all-modes | 36 tests (9 distros × 4 modes) |
| `--distro ubuntu --all-modes` | 8 tests (2 ubuntu versions × 4 modes) |
| `--distro rockylinux:9 --all-modes` | 4 tests (1 distro × 4 modes) |

### Complete Coverage Matrix

To test all combinations (36 total tests):

```bash
./test-docker.sh --all-modes  # 9 distros × 4 modes = 36 Docker builds!
```

**Estimated time:** 1-3 hours depending on network speed

### Recommended Testing Strategy

```bash
# Quick smoke test (1-2 minutes per distro)
./test-docker.sh --distro ubuntu:22.04
./test-docker.sh --distro fedora:39
./test-docker.sh --distro rockylinux:9

# Or test all distros with default mode (10-20 minutes total)
./test-docker.sh

# Full test before release (1-3 hours)
./test-docker.sh --all-modes
```

