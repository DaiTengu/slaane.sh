# Changelog

All notable changes to this unholy creation are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), but filtered through the warp.

## [Unreleased]

### Changed
- **Documentation**: Prioritized curl-based installation as the recommended path to corruption
- **Installation flow**: Simplified installation and uninstallation instructions for maximum ease of use
- **Uninstallation guide**: Enhanced with `slaane.sh uninstall --all` command and selective banishment options

## [0.2.0] - The Simplified Grimoire

### Added
- **Master script (`slaane.sh`)**: A single dark altar for all corruption rituals (install, update, uninstall, list, test)
- **Declarative module system**: Modules now manifest through simple variable declarations (`MODULE_DIR`, `MODULE_REPO`, etc.) with optional hook functions for custom heresies
- **Module discovery**: The warp automatically reveals all modules dwelling in `modules/`
- **Generic handlers**: Centralized summoning rituals consolidated into the tome `lib/modules.sh`
- **MIT License**: The dark knowledge is now freely shared with all seekers
- **Core vs optional modules**: `MODULE_CORE` marks critical blessings; `MODULE_OPTIONAL` marks expendable servants
- **Module API documentation**: The sacred `docs/MODULE_API.md` now speaks plainly to initiates
- **Ritual subcommands**: `update` refreshes corruption, `uninstall` banishes modules, `list` reveals the pantheon, `test` verifies the bindings

### Changed
- **Module naming**: Stripped the numerical prefixes—`10-bash-it.sh` becomes simply `bash-it.sh`
- **Module structure**: Verbose incantations purged; modules now wield declarative variables with optional hooks
- **Installation flow**: Generic handlers channel all manifestations through unified rites
- **Test suite**: Verification rituals now properly distinguish critical failures from optional sacrifices
- **Docker testing**: Containers now receive proper preparations (procps-ng, locale bindings) for blesh operation
- **Documentation**: README updated with new command structure and architectural revelations
- **Global availability**: `slaane.sh` now answers from anywhere via `~/.local/bin` symlink

### Removed
- **Bloated module format**: The old 60-180 line monstrosities have been reduced to 5-77 lines of elegant corruption
- **Hardcoded module lists**: Replaced with dynamic discovery—the warp knows its own

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

