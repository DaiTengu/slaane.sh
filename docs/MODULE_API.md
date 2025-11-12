# Slaane.sh Module API Specification

This document defines the API for creating modules for Slaane.sh. Modules are self-describing components that can be installed, updated, uninstalled, and tested automatically by the core system.

## Table of Contents

- [Module Structure](#module-structure)
- [Metadata Format](#metadata-format)
- [Module Interface](#module-interface)
- [Installation Methods](#installation-methods)
- [Update Methods](#update-methods)
- [Dependencies](#dependencies)
- [Configuration Files](#configuration-files)
- [Testing](#testing)
- [Examples](#examples)

## Module Structure

### File Naming

- Module files must be named `<module-name>.sh` where `<module-name>` matches the `MODULE_NAME` in metadata
- Examples: `bash-it.sh`, `zoxide.sh`, `pyenv.sh`
- **No prefix numbers** - dependencies handle install order
- Module name must match filename (without `.sh` extension)

### File Organization

Each module consists of:
- `modules/<name>.sh` - Module script file (required)
- `modules/<name>.conf` - Module metadata file (optional, can be embedded in script)

## Metadata Format

Modules must declare metadata that describes their installation, update, uninstall, and testing requirements. Metadata can be provided in two formats:

### Format A: Embedded Metadata (Recommended)

Metadata is embedded directly in the module script file between `# Metadata: START` and `# Metadata: END` markers:

```bash
#!/usr/bin/env bash
# Module: bash-it installation
# Metadata: START
MODULE_NAME="bash-it"
MODULE_DESCRIPTION="Bash-it framework for shell customization"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="true"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="git_clone"
MODULE_INSTALL_DIRS="$HOME/.bash_it"
MODULE_INSTALL_REPO="https://github.com/Bash-it/bash-it.git"
MODULE_INSTALL_ARGS="--depth=1"
MODULE_UPDATE_METHOD="component_command"
MODULE_UPDATE_DIR="$HOME/.bash_it"
MODULE_UNINSTALL_DIRS="$HOME/.bash_it"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="$HOME/.bash_it"
MODULE_TEST_FILES="$HOME/.bash_it/bash_it.sh"
# Metadata: END

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/module-handlers.sh"
# ... rest of module code
```

### Format B: Separate Configuration File

Metadata can be in a separate `.conf` file:

```bash
# modules/bash-it.conf
MODULE_NAME="bash-it"
MODULE_DESCRIPTION="Bash-it framework for shell customization"
# ... (all other metadata fields)
```

**Note:** If both embedded metadata and `.conf` file exist, the `.conf` file takes precedence.

### Required Metadata Fields

| Field | Type | Description |
|-------|------|-------------|
| `MODULE_NAME` | string | Module name (must match filename without `.sh`) |
| `MODULE_DESCRIPTION` | string | Human-readable description |
| `MODULE_ENABLED_BY_DEFAULT` | boolean | Whether module is enabled by default (`true`/`false`) |
| `MODULE_IS_CORE` | boolean | Whether module is core (failure causes installer to fail) (`true`/`false`) |
| `MODULE_INSTALL_METHOD` | string | Installation method (see [Installation Methods](#installation-methods)) |
| `MODULE_UNINSTALL_DIRS` | string | Space-separated list of directories to remove on uninstall |

### Optional Metadata Fields

| Field | Type | Description |
|-------|------|-------------|
| `MODULE_DEPENDS` | string | Space-separated list of module names this module depends on |
| `MODULE_INSTALL_DIRS` | string | Space-separated list of directories created during install |
| `MODULE_INSTALL_REPO` | string | Git repository URL (for `git_clone` method) |
| `MODULE_INSTALL_ARGS` | string | Additional arguments for git clone |
| `MODULE_UPDATE_METHOD` | string | Update method (see [Update Methods](#update-methods)) |
| `MODULE_UPDATE_DIR` | string | Directory to update (for `git_pull` method) |
| `MODULE_CONFIG_FILES` | string | Space-separated list of config files installed by module |
| `MODULE_TEST_DIRS` | string | Space-separated list of directories to check for existence |
| `MODULE_TEST_FILES` | string | Space-separated list of files to check for existence |
| `MODULE_TEST_BINARIES` | string | Space-separated list of binaries to check for in PATH |
| `MODULE_TEST_COMMAND` | string | Shell command to run for testing (returns 0 on success) |

## Module Interface

All modules must implement a standardized interface using the same function names.

### Required Functions

#### `main_module()`

Main installation function. Called when module is installed.

```bash
main_module() {
    # Module-specific installation logic
    # Has access to all metadata variables: $MODULE_NAME, $MODULE_INSTALL_DIRS, etc.
    # Can call generic handlers or implement custom logic
    # Return 0 on success, 1 on failure
}
```

**Context:** All metadata variables are available as environment variables when this function is called.

### Optional Functions

#### `update_module()`

Custom update function. Only needed if `MODULE_UPDATE_METHOD="custom"`.

```bash
update_module() {
    # Custom update logic
    # Has access to all metadata variables
    # Return 0 on success, 1 on failure
}
```

#### `uninstall_module()`

Custom uninstall function. Only needed if generic uninstall handler is insufficient.

```bash
uninstall_module() {
    # Custom uninstall logic
    # Has access to all metadata variables
    # Return 0 on success, 1 on failure
}
```

#### `check_module_installed()`

Check if module is installed. Used for testing and verification.

```bash
check_module_installed() {
    # Check if component is installed
    # Return 0 if installed, 1 if not
}
```

## Installation Methods

The `MODULE_INSTALL_METHOD` field determines how the module is installed:

### `git_clone`

Clone a git repository to a directory.

**Required fields:**
- `MODULE_INSTALL_REPO` - Git repository URL
- `MODULE_INSTALL_DIRS` - Target directory (usually one directory)

**Optional fields:**
- `MODULE_INSTALL_ARGS` - Additional git clone arguments (e.g., `--depth=1`)

**Example:**
```bash
MODULE_INSTALL_METHOD="git_clone"
MODULE_INSTALL_REPO="https://github.com/Bash-it/bash-it.git"
MODULE_INSTALL_DIRS="$HOME/.bash_it"
MODULE_INSTALL_ARGS="--depth=1"
```

### `pip`

Install via pip (Python package manager).

**Required fields:**
- `MODULE_INSTALL_DIRS` - Directory where pip installs (usually `$HOME/.local`)

**Example:**
```bash
MODULE_INSTALL_METHOD="pip"
MODULE_INSTALL_DIRS="$HOME/.local"
```

### `package_manager`

Install via system package manager (apt, dnf, pacman, etc.).

**Required fields:**
- None (package name is derived from module name or specified in `main_module()`)

**Example:**
```bash
MODULE_INSTALL_METHOD="package_manager"
```

### `download_script`

Download and run an installer script (curl|bash pattern).

**Required fields:**
- `MODULE_INSTALL_REPO` - URL to installer script

**Example:**
```bash
MODULE_INSTALL_METHOD="download_script"
MODULE_INSTALL_REPO="https://raw.githubusercontent.com/user/repo/main/install.sh"
```

### `custom`

Use module's custom `main_module()` function for installation.

**Required fields:**
- None (module handles installation entirely in `main_module()`)

**Example:**
```bash
MODULE_INSTALL_METHOD="custom"
```

## Update Methods

The `MODULE_UPDATE_METHOD` field determines how the module is updated:

### `git_pull`

Run `git pull` in the install directory.

**Required fields:**
- `MODULE_UPDATE_DIR` - Directory containing git repository

**Example:**
```bash
MODULE_UPDATE_METHOD="git_pull"
MODULE_UPDATE_DIR="$HOME/.bash_it"
```

### `pip_upgrade`

Run `pip install --upgrade` for the package.

**Required fields:**
- None (package name derived from module or specified in `update_module()`)

**Example:**
```bash
MODULE_UPDATE_METHOD="pip_upgrade"
```

### `component_command`

Run the component's own update command.

**Required fields:**
- None (command is component-specific, e.g., `bash-it update`)

**Example:**
```bash
MODULE_UPDATE_METHOD="component_command"
```

### `reinstall`

Remove and re-run installation.

**Required fields:**
- None

**Example:**
```bash
MODULE_UPDATE_METHOD="reinstall"
```

### `custom`

Use module's custom `update_module()` function.

**Required fields:**
- None

**Example:**
```bash
MODULE_UPDATE_METHOD="custom"
```

### `none`

Component doesn't support updates or self-updates.

**Required fields:**
- None

**Example:**
```bash
MODULE_UPDATE_METHOD="none"
```

## Dependencies

Modules can declare dependencies on other modules using `MODULE_DEPENDS`.

### Dependency Format

```bash
MODULE_DEPENDS="bash-it fzf"
```

**Rules:**
- Dependencies are space-separated module names
- Dependencies must exist (validation will fail if missing)
- Circular dependencies are detected and prevented
- Dependencies are installed before the dependent module
- If a dependency fails to install, the dependent module installation is skipped

### Example

```bash
# Module: liquidprompt (depends on bash-it)
MODULE_DEPENDS="bash-it"
```

## Configuration Files

Modules can install configuration files that are tracked separately from the module itself.

### Declaring Config Files

```bash
MODULE_CONFIG_FILES="$HOME/.bashrc $HOME/.blerc"
```

### Config File Update Behavior

When updating, config files can be handled in three ways:

1. **Overwrite** (`--config-overwrite`): Backup existing config, install new version
2. **Keep** (`--config-keep`): Save new config as `<config>.new`, keep existing
3. **Ask** (default): Prompt user for each config file

**Note:** Config files are backed up before modification (backup suffix: `.pre-slaanesh-<timestamp>`).

## Testing

Modules can declare how they should be tested.

### Test Metadata Fields

- `MODULE_TEST_DIRS` - Directories that must exist
- `MODULE_TEST_FILES` - Files that must exist
- `MODULE_TEST_BINARIES` - Binaries that must be in PATH
- `MODULE_TEST_COMMAND` - Shell command to run (returns 0 on success)

### Test Function

If `check_module_installed()` is defined, it will be used for testing. Otherwise, generic tests based on metadata are used.

### Example

```bash
MODULE_TEST_DIRS="$HOME/.bash_it"
MODULE_TEST_FILES="$HOME/.bash_it/bash_it.sh"
MODULE_TEST_BINARIES=""
MODULE_TEST_COMMAND="test -d $HOME/.bash_it && test -f $HOME/.bash_it/bash_it.sh"
```

## Core vs Default Modules

### Core Modules

Core modules are always installed and installation failure causes the installer to fail.

```bash
MODULE_IS_CORE="true"
MODULE_ENABLED_BY_DEFAULT="true"
```

**Examples:** bash-it, ble.sh, fzf

### Default Modules

Default modules are enabled by default but installation failure is non-fatal.

```bash
MODULE_IS_CORE="false"
MODULE_ENABLED_BY_DEFAULT="true"
```

**Examples:** zoxide, pyenv, goenv

### Optional Modules

Optional modules are only installed with explicit flags.

```bash
MODULE_IS_CORE="false"
MODULE_ENABLED_BY_DEFAULT="false"
```

**Examples:** bashhub

## Examples

### Example 1: Simple Git Clone Module

```bash
#!/usr/bin/env bash
# Module: bash-it installation
# Metadata: START
MODULE_NAME="bash-it"
MODULE_DESCRIPTION="Bash-it framework for shell customization"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="true"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="git_clone"
MODULE_INSTALL_DIRS="$HOME/.bash_it"
MODULE_INSTALL_REPO="https://github.com/Bash-it/bash-it.git"
MODULE_INSTALL_ARGS="--depth=1"
MODULE_UPDATE_METHOD="component_command"
MODULE_UPDATE_DIR="$HOME/.bash_it"
MODULE_UNINSTALL_DIRS="$HOME/.bash_it"
MODULE_CONFIG_FILES=""
MODULE_TEST_DIRS="$HOME/.bash_it"
MODULE_TEST_FILES="$HOME/.bash_it/bash_it.sh"
# Metadata: END

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/module-handlers.sh"

main_module() {
    # Generic handler will handle git_clone, but we can add custom logic
    if [[ -d "$HOME/.bash_it" ]]; then
        log_warning "bash-it already installed"
        return 0
    fi
    
    # Generic handler will be called automatically
    # Or we can call it explicitly
    install_via_git_clone "$MODULE_NAME"
    
    # Additional custom setup
    bash "$HOME/.bash_it/install.sh" --silent --no-modify-config
    return $?
}
```

### Example 2: Custom Installation Module

```bash
#!/usr/bin/env bash
# Module: zoxide installation
# Metadata: START
MODULE_NAME="zoxide"
MODULE_DESCRIPTION="Smart directory jumper"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="false"
MODULE_DEPENDS=""
MODULE_INSTALL_METHOD="custom"
MODULE_UNINSTALL_DIRS=""
MODULE_UPDATE_METHOD="reinstall"
MODULE_TEST_BINARIES="zoxide"
# Metadata: END

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/module-handlers.sh"

main_module() {
    # Custom installation logic
    # Try package manager first
    if install_zoxide_from_package_manager; then
        return 0
    fi
    
    # Fall back to official script
    if install_zoxide_from_official_script; then
        return 0
    fi
    
    return 1
}
```

### Example 3: Module with Dependencies

```bash
#!/usr/bin/env bash
# Module: liquidprompt installation
# Metadata: START
MODULE_NAME="liquidprompt"
MODULE_DESCRIPTION="Adaptive prompt for bash"
MODULE_ENABLED_BY_DEFAULT="true"
MODULE_IS_CORE="false"
MODULE_DEPENDS="bash-it"
MODULE_INSTALL_METHOD="custom"
MODULE_UNINSTALL_DIRS=""
MODULE_UPDATE_METHOD="none"
# Metadata: END

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/module-handlers.sh"

main_module() {
    # bash-it must be installed first (dependency)
    if [[ ! -d "$HOME/.bash_it" ]]; then
        log_error "bash-it is required but not installed"
        return 1
    fi
    
    # Install liquidprompt theme
    # ... custom logic ...
}
```

## Best Practices

1. **Use embedded metadata** for simple modules (one less file to maintain)
2. **Use separate .conf files** for complex modules with extensive metadata
3. **Always declare `MODULE_UNINSTALL_DIRS`** for safety (only remove what's explicitly declared)
4. **Validate paths** in `MODULE_UNINSTALL_DIRS` are within `$HOME`
5. **Use `MODULE_IS_CORE="true"`** only for essential modules
6. **Declare dependencies** explicitly to ensure correct install order
7. **Test modules** using both metadata-based tests and custom `check_module_installed()` if needed

## Error Handling

- Modules should return 0 on success, 1 on failure
- Core modules that fail cause the installer to exit with error
- Default/optional modules that fail are logged but don't stop installation
- Always validate prerequisites before attempting installation
- Use `log_error()`, `log_warning()`, `log_info()`, `log_success()` from `lib/common.sh`

