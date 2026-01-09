# Slaane.sh Module API

This document explains how to create modules for Slaane.sh. The system is designed to be **simple** - most modules are just a few lines of configuration.

## Quick Start

### Simplest Module (3 lines)

A module that just clones a git repo:

```bash
#!/usr/bin/env bash
# mymodule - Description of what it does

MODULE_DIR="$HOME/.mymodule"
MODULE_REPO="https://github.com/user/repo.git"
```

That's it. The framework handles:
- Cloning the repo
- Checking if already installed (`[[ -d $MODULE_DIR ]]`)
- Updates (`git pull`)
- Uninstall (`rm -rf $MODULE_DIR`)

### Module with Post-Install Hook

Some tools need a setup step after cloning:

```bash
#!/usr/bin/env bash
# fzf - Fuzzy finder

MODULE_DIR="$HOME/.fzf"
MODULE_REPO="https://github.com/junegunn/fzf.git"

post_install() {
    "$MODULE_DIR/install" --bin --no-update-rc
}
```

### Module with Binary Check

For tools installed to PATH (not a directory):

```bash
#!/usr/bin/env bash
# zoxide - Smart cd replacement

MODULE_BIN="zoxide"

install() {
    # Your custom installation logic
    curl -sSfL https://example.com/install.sh | bash
}
```

## Module Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MODULE_DIR` | No* | Directory where module is installed |
| `MODULE_REPO` | No* | Git repository URL to clone |
| `MODULE_BIN` | No* | Binary name to check in PATH |
| `MODULE_SCRIPT` | No | URL of installer script (curl\|bash) |
| `MODULE_CORE` | No | Set to `true` if failure should abort install |
| `MODULE_OPTIONAL` | No | Set to `true` if requires explicit flag to install |
| `MODULE_CONFIG` | No | Config file to install to $HOME |

*At least one of `MODULE_DIR`, `MODULE_BIN`, or a custom `install()` function is required.

## Optional Functions

Override these only when the defaults don't work:

### `is_installed()`

Custom check for whether module is installed.

```bash
is_installed() {
    [[ -f "$HOME/.mymodule/bin/mytool" ]] && command_exists mytool
}
```

**Default behavior:**
- If `MODULE_BIN` set: `command_exists $MODULE_BIN`
- If `MODULE_DIR` set: `[[ -d $MODULE_DIR ]]`

### `install()`

Full custom installation logic.

```bash
install() {
    # Try binary download first
    if download_binary; then
        return 0
    fi
    # Fall back to package manager
    run_as_root $PKG_INSTALL mypackage
}
```

**Default behavior:** `git clone $MODULE_REPO $MODULE_DIR`

### `post_install()`

Run after successful git clone. Use for setup scripts.

```bash
post_install() {
    cd "$MODULE_DIR" && ./setup.sh
}
```

### `update()`

Custom update logic.

```bash
update() {
    "$MODULE_DIR/bin/mytool" self-update
}
```

**Default behavior:** `cd $MODULE_DIR && git pull`, then calls `post_install()` if defined.

### `uninstall()`

Custom uninstall logic.

```bash
uninstall() {
    rm -rf "$MODULE_DIR"
    pip uninstall -y mytool
}
```

**Default behavior:** `rm -rf $MODULE_DIR`

## Module Types

### Core Modules

Always installed. Installation failure aborts the entire install.

```bash
MODULE_CORE=true
```

Examples: bash-it, blesh, fzf

### Default Modules

Installed by default, but failure is non-fatal.

```bash
# No special flags needed - this is the default
```

Examples: pyenv, goenv, zoxide, thefuck, nano

### Optional Modules

Only installed with explicit flags (e.g., `--with-bashhub`).

```bash
MODULE_OPTIONAL=true
```

Examples: bashhub

## Available Helpers

These functions from `lib/common.sh` are available in modules:

| Function | Description |
|----------|-------------|
| `command_exists <cmd>` | Check if command exists |
| `log_info <msg>` | Print info message |
| `log_success <msg>` | Print success message |
| `log_warning <msg>` | Print warning message |
| `log_error <msg>` | Print error message |
| `run_as_root <cmd>` | Run command with sudo if needed |
| `$PKG_MANAGER` | Detected package manager (apt, dnf, pacman, etc.) |
| `$PKG_INSTALL` | Package install command (e.g., `apt-get install -y`) |
| `$OS_FAMILY` | OS family (debian, rhel, arch, gentoo) |
| `$SCRIPT_DIR` | Path to slaane.sh repository |

## Complete Examples

### Example 1: Simple Git Clone

```bash
#!/usr/bin/env bash
# goenv - Go version manager

MODULE_DIR="$HOME/.goenv"
MODULE_REPO="https://github.com/go-nv/goenv.git"
```

### Example 2: Git Clone with Plugins

```bash
#!/usr/bin/env bash
# pyenv - Python version manager

MODULE_DIR="$HOME/.pyenv"
MODULE_REPO="https://github.com/pyenv/pyenv.git"

post_install() {
    git clone https://github.com/pyenv/pyenv-virtualenv.git \
        "$MODULE_DIR/plugins/pyenv-virtualenv" || true
    git clone https://github.com/pyenv/pyenv-update.git \
        "$MODULE_DIR/plugins/pyenv-update" || true
}

update() {
    if [[ -d "$MODULE_DIR/plugins/pyenv-update" ]]; then
        "$MODULE_DIR/bin/pyenv" update
    else
        (cd "$MODULE_DIR" && git pull)
    fi
}
```

### Example 3: Build from Source

```bash
#!/usr/bin/env bash
# blesh - Bash Line Editor

MODULE_DIR="$HOME/.local/share/blesh"
MODULE_CORE=true

BLESH_SRC="$HOME/.local/src/blesh"

is_installed() {
    [[ -f "$MODULE_DIR/ble.sh" ]]
}

install() {
    git clone --recursive https://github.com/akinomyoga/ble.sh.git "$BLESH_SRC"
    (cd "$BLESH_SRC" && make install PREFIX="$HOME/.local")
}

update() {
    (cd "$BLESH_SRC" && git pull && make install PREFIX="$HOME/.local")
}

uninstall() {
    rm -rf "$MODULE_DIR" "$BLESH_SRC"
}
```

### Example 4: Multiple Install Methods

```bash
#!/usr/bin/env bash
# zoxide - Smart directory jumper

MODULE_BIN="zoxide"

install() {
    # Try precompiled binary (fastest, no sudo)
    local arch=$(uname -m)
    case "$arch" in
        x86_64)  binary="zoxide-x86_64-unknown-linux-musl" ;;
        aarch64) binary="zoxide-aarch64-unknown-linux-musl" ;;
        *) binary="" ;;
    esac
    
    if [[ -n "$binary" ]]; then
        mkdir -p "$HOME/.local/bin"
        curl -sSfL "https://github.com/.../download/${binary}.tar.gz" \
            | tar xz -C "$HOME/.local/bin/" zoxide && return 0
    fi
    
    # Fall back to package manager
    run_as_root $PKG_INSTALL zoxide
}

uninstall() {
    rm -f "$HOME/.local/bin/zoxide"
}
```

### Example 5: Pip Package

```bash
#!/usr/bin/env bash
# thefuck - Command correction

MODULE_BIN="thefuck"

install() {
    pip3 install --user thefuck || pip install --user thefuck
}

update() {
    pip3 install --user --upgrade thefuck
}

uninstall() {
    pip3 uninstall -y thefuck
}
```

### Example 6: Optional Module

```bash
#!/usr/bin/env bash
# bashhub - Cloud command history (requires account)

MODULE_DIR="$HOME/.bashhub"
MODULE_OPTIONAL=true

install() {
    log_warning "bashhub requires account at bashhub.com"
    curl -fsSL https://bashhub.com/setup | bash
}
```

## File Structure

```
modules/
├── bash-it.sh    # Core module
├── blesh.sh      # Core module  
├── fzf.sh        # Core module
├── goenv.sh      # Default module (3 lines!)
├── pyenv.sh      # Default module
├── zoxide.sh     # Default module
├── thefuck.sh    # Default module
├── nano.sh       # Default module
└── bashhub.sh    # Optional module
```

## Testing Your Module

```bash
# List all modules
./slaane.sh list

# Test if module is detected as installed
./slaane.sh test --module mymodule

# Force reinstall
./slaane.sh install --force --skip=bash-it,blesh,fzf

# Test just your module
source lib/common.sh
source lib/modules.sh
init_common
install_module mymodule
```

## Best Practices

1. **Keep it simple** - If you're writing more than 20 lines, reconsider the approach
2. **Use `MODULE_DIR` + `MODULE_REPO`** when possible - the framework handles everything
3. **Prefer local installs** - `$HOME/.local/bin` over system packages when possible
4. **Graceful fallbacks** - Try binary download → official script → package manager
5. **Don't reinvent** - Use the helper functions from `lib/common.sh`
