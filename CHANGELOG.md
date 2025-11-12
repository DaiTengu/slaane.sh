# Changelog

All notable changes to this unholy creation are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), but filtered through the warp.

## [Unreleased]

### Changed
- **Documentation**: Prioritized curl-based installation as the recommended path to corruption
- **Installation flow**: Simplified installation and uninstallation instructions for maximum ease of use
- **Uninstallation guide**: Enhanced with `slaane.sh uninstall --all` command and selective banishment options

## [0.2.0] - Modular API/SDK System

### Added
- **Master script (`slaane.sh`)**: Unified interface for all operations (install, update, uninstall, list, test)
- **Modular API/SDK system**: Self-describing modules with metadata-driven installation
- **Module discovery**: Automatic discovery of modules in `modules/` directory
- **Generic handlers**: Centralized install/update/uninstall/test operations based on module metadata
- **Installation state tracking**: Explicit tracking of installed modules in `~/.slaane.sh/installed-modules`
- **Dependency resolution**: Automatic dependency resolution with cycle detection
- **MIT License**: Project is now licensed under the MIT License
- **Module metadata**: Embedded metadata format or separate `.conf` files
- **Standardized module interface**: All modules use `main_module()`, `update_module()`, `uninstall_module()`, `check_module_installed()`
- **Core vs default modules**: `MODULE_IS_CORE` flag for critical modules
- **Module API documentation**: Comprehensive `docs/MODULE_API.md` specification
- **Update subcommand**: `slaane.sh update` with component-specific or repository-wide updates
- **Uninstall subcommand**: `slaane.sh uninstall` with module-specific or full cleanup
- **List subcommand**: `slaane.sh list` to view available or installed modules
- **Test subcommand**: `slaane.sh test` using generic test handlers

### Changed
- **Module naming**: Removed prefix numbers (e.g., `10-bash-it.sh` → `bash-it.sh`)
- **Module structure**: All modules now follow standardized API with embedded metadata
- **Installation flow**: Now uses generic handlers and module discovery
- **Test suite**: Updated to use generic test handlers and module discovery
- **Docker tests**: Updated to use `slaane.sh install` instead of `install.sh`
- **Documentation**: Updated README with master script commands and new architecture
- **Global availability**: `slaane.sh` command now available system-wide via `~/.local/bin` symlink

### Removed
- **Old module format**: All modules recreated in new standardized format
- **Hardcoded module lists**: Replaced with dynamic discovery from metadata

## [0.1.x] - Initial Release

### Added
- **Nano syntax highlighting**: For heretics who embrace nano over vim, syntax highlighting is now automatically installed. The installer ensures `unzip` and `wget` dependencies are met.
- **Bootstrap support for curl | bash**: The installer now detects when piped from stdin and automatically downloads the repository before execution, allowing one-liner installations without git.
- **Core blessings**: bash-it framework, ble.sh line editor, fzf fuzzy finder
- **Development tools**: zoxide (smart directory jumping), pyenv (Python sorcery), goenv (Go manipulation)
- **Quality of life**: thefuck (command correction)
- **Modular installation system**: Each component installs independently, allowing selective corruption
- **Cross-distribution support**: Automatically detects and adapts to RHEL, Debian, Arch, and Gentoo systems
- **Cross-architecture support**: Works on x86_64, ARM64, and other architectures
- **Prerequisite management**: Optional automatic installation of missing system dependencies
- **Testing framework**: Local and Docker-based testing across multiple distributions

### Fixed
- **Liquidprompt git branch display**: Corrupted bash-it's default `liquidprompt.theme.bash` to properly manifest git branch names in prompts. The original theme's `_lp_git_branch()` function failed to bind the branch variable.
- **Bash-it component detection**: Corrected the manifestation rituals for aliases and completions. The installer was seeking `.alias.bash` and `.completion.bash` files, but bash-it's repository actually contains `.aliases.bash` and `.completion.bash` (with the completion directory being singular `completion/` not plural). Both installation and testing scripts now correctly bind these components.
- **zoxide installation**: Added EPEL repository support for RHEL-based systems
- **thefuck installation**: Intelligent pip detection (prioritizes pyenv's pip, falls back gracefully)
- **Prerequisites**: Fixed export of `INSTALL_PREREQS` flag to module subprocesses
- **Critical module handling**: Installation now fails if core modules (bash-it, ble.sh, fzf) fail, but continues for optional components
- **Docker testing**: Fixed arithmetic bug in test counters that caused early exit
- **Test suite**: Removed `set -e` to allow full test reporting instead of failing on first error

### Changed
- **Project naming**: Renamed from `portable-bash-env` to `Slaane.sh` (embracing Chaos)
- **Documentation**: Complete rewrite of README and all documentation
- **Liquidprompt theme**: Automatically replaces bash-it's liquidprompt theme with corrected version
- Updated testing suite to verify nano syntax highlighting installation
- Improved error handling for missing dependencies (unzip, wget) in nano module
- Testing rituals now properly detect all bash-it components using correct file extensions

## [Initial Release]

### Added
- **Core blessings**: bash-it framework, ble.sh line editor, fzf fuzzy finder
- **Development tools**: zoxide (smart directory jumping), pyenv (Python sorcery), goenv (Go manipulation)
- **Quality of life**: thefuck (command correction)
- **Modular installation system**: Each component installs independently, allowing selective corruption
- **Cross-distribution support**: Automatically detects and adapts to RHEL, Debian, Arch, and Gentoo systems
- **Cross-architecture support**: Works on x86_64, ARM64, and other architectures
- **Prerequisite management**: Optional automatic installation of missing system dependencies
- **Testing framework**: Local and Docker-based testing across multiple distributions

### Fixed
- **zoxide installation**: Added EPEL repository support for RHEL-based systems
- **thefuck installation**: Intelligent pip detection (prioritizes pyenv's pip, falls back gracefully)
- **Prerequisites**: Fixed export of `INSTALL_PREREQS` flag to module subprocesses
- **Critical module handling**: Installation now fails if core modules (bash-it, ble.sh, fzf) fail, but continues for optional components
- **Docker testing**: Fixed arithmetic bug in test counters that caused early exit
- **Test suite**: Removed `set -e` to allow full test reporting instead of failing on first error

### Changed
- **Project naming**: Renamed from `portable-bash-env` to `Slaane.sh` (embracing Chaos)
- **Documentation**: Complete rewrite of README and all documentation
- **Liquidprompt theme**: Automatically replaces bash-it's liquidprompt theme with corrected version

---

*The Emperor Protects... but Slaane.sh Perfects.*

