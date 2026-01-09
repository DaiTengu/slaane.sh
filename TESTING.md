# Testing Guide

## Quick Start

### Local Testing

```bash
./test.sh
```

### Docker Testing

```bash
# Test Rocky 9
./test-docker.sh rocky9

# Test Ubuntu 22.04
./test-docker.sh ubuntu22

# Test all distributions
./test-docker.sh

# Interactive shell for debugging
./test-docker.sh rocky9 -i
```

## Available Distributions

| Name | Image |
|------|-------|
| `rocky9` | rockylinux:9 |
| `rocky8` | rockylinux:8 |
| `ubuntu22` | ubuntu:22.04 |
| `ubuntu20` | ubuntu:20.04 |
| `debian12` | debian:12 |
| `debian11` | debian:11 |
| `fedora39` | fedora:39 |
| `fedora38` | fedora:38 |
| `arch` | archlinux:latest |

## What Gets Tested

### Core Modules (must pass)
- bash-it: Directory and script exist
- blesh: Installed and blerc exists
- fzf: Directory exists and binary works

### Default Modules
- pyenv: Directory and binary exist
- goenv: Directory and binary exist
- zoxide: Binary accessible
- thefuck: Binary accessible
- nano: Syntax highlighting directory exists

### Configuration
- .bashrc exists and contains bash-it config
- slaane.sh symlink in ~/.local/bin

### Functional
- slaane.sh help/list commands work
- bashrc can be sourced without errors

## Debugging Failed Tests

```bash
# Start interactive container
./test-docker.sh rocky9 -i

# Inside container:
./test.sh                      # Re-run tests
source ~/.bashrc               # Test bashrc
fzf --version                  # Test specific tools
ls -la ~/.bash_it              # Check installations
```

## Adding Tests

Edit `test.sh` and add checks:

```bash
check "my feature works" "command -v mytool &>/dev/null"
check "my file exists" "[[ -f '$HOME/.myconfig' ]]"
```
