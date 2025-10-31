# Changelog

All notable changes to this unholy creation are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), but filtered through the warp.

## [Unreleased]

### Added
- **Nano syntax highlighting**: For heretics who embrace nano over vim, syntax highlighting is now automatically installed. The installer ensures `unzip` and `wget` dependencies are met.
- **Bootstrap support for curl | bash**: The installer now detects when piped from stdin and automatically downloads the repository before execution, allowing one-liner installations without git.

### Fixed
- **Liquidprompt git branch display**: Corrupted bash-it's default `liquidprompt.theme.bash` to properly manifest git branch names in prompts. The original theme's `_lp_git_branch()` function failed to bind the branch variable.

### Changed
- Updated testing suite to verify nano syntax highlighting installation
- Improved error handling for missing dependencies (unzip, wget) in nano module

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

