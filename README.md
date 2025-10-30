# Portable Bash Environment

A modular, cross-distribution bash environment installer that works seamlessly across RHEL, Debian, Arch, and other Linux distributions, supporting multiple CPU architectures.

## Features

### Core Components

- **[bash-it](https://github.com/Bash-it/bash-it)** - Comprehensive bash framework with themes, plugins, and aliases
- **[ble.sh](https://github.com/akinomyoga/ble.sh)** - Advanced bash line editor with:
  - Syntax highlighting
  - Auto-suggestions
  - Vim modes
  - Enhanced completion
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder for command history, files, and more
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart directory jumper (modern `cd` replacement)
- **[pyenv](https://github.com/pyenv/pyenv)** - Python version manager
- **[goenv](https://github.com/go-nv/goenv)** - Go version manager
- **[thefuck](https://github.com/nvbn/thefuck)** - Command corrector

### Optional Components

- **[bashhub](https://bashhub.com)** - Cloud command history (requires account registration)

## Quick Start

### Installation

```bash
# Clone the repository
git clone <your-repo-url> ~/portable-bash-env
cd ~/portable-bash-env

# Run the installer
./install.sh
```

### After Installation

```bash
# Activate the new environment
source ~/.bashrc

# Or restart your shell
exec bash
```

## Installation Options

### Default Installation

Installs all core components:

```bash
./install.sh
```

### Minimal Installation

Only installs bash-it, ble.sh, and fzf:

```bash
./install.sh --minimal
```

### Skip Specific Components

```bash
# Skip goenv and thefuck
./install.sh --skip=goenv,thefuck
```

### Install with Bashhub

```bash
./install.sh --with-bashhub
```

### Auto-Install Prerequisites

If prerequisites are missing, install them automatically with sudo:

```bash
./install.sh --install-prereqs
```

### Force Reinstallation

```bash
./install.sh --force
```

## Prerequisites

The installer requires the following tools to be installed:

- `git`
- `curl`
- `make`
- C compiler (`gcc` or build-essential)

### Manual Prerequisites Installation

**Debian/Ubuntu:**
```bash
sudo apt-get update && sudo apt-get install -y git curl make build-essential
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install -y git curl make gcc gcc-c++
```

**Arch Linux:**
```bash
sudo pacman -S git curl make base-devel
```

Or use the installer's built-in option:
```bash
./install.sh --install-prereqs
```

## Deployment to Remote Servers

### Method 1: Tarball Transfer

```bash
# Create tarball
cd ~
tar czf portable-bash-env.tar.gz portable-bash-env/

# Transfer to remote server
scp portable-bash-env.tar.gz user@remote:~/

# On remote server
ssh user@remote
tar xzf portable-bash-env.tar.gz
cd portable-bash-env
./install.sh
```

### Method 2: Git Clone on Remote

```bash
ssh user@remote
git clone <your-repo-url> ~/portable-bash-env
cd ~/portable-bash-env
./install.sh
```

### Method 3: Direct Installation (if hosted publicly)

```bash
ssh user@remote
curl -fsSL <raw-url>/install.sh | bash
```

## Configuration

### Configuration Files

- **`~/.bashrc`** - Main bash configuration (installed from `config/bashrc.template`)
- **`~/.blerc`** - ble.sh configuration (extensive customization, 1300+ lines)
- **`~/.bashrc.local`** - Optional local overrides (not overwritten by installer)

### Customizing Enabled Components

Edit `config/bash-it-components` to change which bash-it aliases, plugins, and completions are enabled:

```bash
# config/bash-it-components
[alias]
git
docker
# ... add more aliases

[plugin]
git
fzf
# ... add more plugins

[completion]
git
docker
# ... add more completions
```

### Local Customization

Create `~/.bashrc.local` for machine-specific settings that won't be overwritten:

```bash
# ~/.bashrc.local
export MY_CUSTOM_VAR="value"
alias myalias='echo hello'
```

## Using the Environment

### Key Features

#### Syntax Highlighting (ble.sh)
Commands are highlighted as you type, showing valid/invalid commands in different colors.

#### Auto-Suggestions (ble.sh)
Press `Shift+Right` or `Shift+End` to accept suggestions based on history.

#### Fuzzy Finding (fzf)
- **`Ctrl+R`** - Search command history
- **`Ctrl+T`** - Find files
- **`Alt+C`** - Change directory

#### Smart Directory Jumping (zoxide)
```bash
# Jump to frequently used directories
z documents
z proj
z ~

# List tracked directories
z -l
```

#### Python Version Management (pyenv)
```bash
# List available Python versions
pyenv install --list

# Install a Python version
pyenv install 3.11.0

# Set global Python version
pyenv global 3.11.0

# Set local project Python version
cd my-project
pyenv local 3.9.0
```

#### Go Version Management (goenv)
```bash
# List available Go versions
goenv install --list

# Install a Go version
goenv install 1.21.0

# Set global Go version
goenv global 1.21.0
```

#### Command Correction (thefuck)
```bash
# Make a typo
$ gti status
fuck

# Corrects to: git status
```

Or use the alias `fuck` directly:
```bash
$ apt install htop  # Permission denied
$ fuck
sudo apt install htop [enter/↑/↓/ctrl+c]
```

## Architecture Support

The installer automatically detects CPU architecture and installs appropriate binaries:

- **x86_64** (Intel/AMD 64-bit)
- **aarch64** (ARM 64-bit)
- **armv7l** (ARM 32-bit)
- Other architectures (falls back to source builds)

## Distribution Support

Tested and supported on:

- **Debian/Ubuntu** (apt)
- **RHEL/CentOS/Fedora/Rocky/AlmaLinux** (dnf/yum)
- **Arch Linux/Manjaro** (pacman)
- **Gentoo** (emerge)

The installer automatically detects your distribution and uses the appropriate package manager.

## Troubleshooting

### Prerequisites Missing

If you see missing prerequisites errors:

```bash
# Option 1: Install manually (see Prerequisites section above)

# Option 2: Let the installer install them
./install.sh --install-prereqs
```

### ble.sh Not Working

Ensure your `.bashrc` sources bash-it properly and that the blesh plugin is enabled:

```bash
bash-it enable plugin blesh
source ~/.bashrc
```

### fzf Integration Issues

The fzf integration with ble.sh is handled automatically via bash-it's blesh plugin. Ensure both are enabled:

```bash
bash-it show plugin | grep -E "(fzf|blesh)"
```

### pyenv Build Failures

Install build dependencies:

**Debian/Ubuntu:**
```bash
sudo apt-get install -y build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
libffi-dev liblzma-dev
```

**RHEL/Fedora:**
```bash
sudo dnf install -y gcc make patch zlib-devel bzip2 bzip2-devel \
readline-devel sqlite sqlite-devel openssl-devel tk-devel \
libffi-devel xz-devel
```

### Checking What's Installed

```bash
# Check bash-it status
bash-it show aliases
bash-it show plugins
bash-it show completions

# Check ble.sh
echo $BLE_VERSION

# Check other tools
fzf --version
zoxide --version
pyenv --version
goenv --version
thefuck --version
```

## Project Structure

```
portable-bash-env/
├── install.sh              # Main installer script
├── lib/
│   └── common.sh          # Common functions (OS detection, logging)
├── modules/
│   ├── 00-prereqs.sh      # Prerequisites checker
│   ├── 10-bash-it.sh      # bash-it installer
│   ├── 20-blesh.sh        # ble.sh installer
│   ├── 30-fzf.sh          # fzf installer
│   ├── 40-zoxide.sh       # zoxide installer
│   ├── 50-pyenv.sh        # pyenv installer
│   ├── 60-goenv.sh        # goenv installer
│   ├── 70-thefuck.sh      # thefuck installer
│   └── 90-bashhub.sh      # bashhub installer (optional)
├── config/
│   ├── bashrc.template    # Template .bashrc
│   ├── blerc              # ble.sh configuration
│   └── bash-it-components # List of enabled bash-it components
└── README.md              # This file
```

## Uninstallation

To remove the portable bash environment:

```bash
# Restore original .bashrc (if backed up)
cp ~/.bashrc.pre-portable-bash-env ~/.bashrc

# Remove installed components
rm -rf ~/.bash_it
rm -rf ~/.local/share/blesh
rm -rf ~/.fzf
rm -rf ~/.pyenv
rm -rf ~/.goenv
rm -f ~/.blerc

# Remove binaries installed via cargo/pip (if desired)
pip3 uninstall thefuck
cargo uninstall zoxide
```

## Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

## License

This project bundles and installs various open-source tools, each with their own licenses. Please refer to the individual project licenses:

- bash-it: MIT
- ble.sh: BSD-3-Clause
- fzf: MIT
- zoxide: MIT
- pyenv: MIT
- goenv: MIT
- thefuck: MIT

## Acknowledgments

This installer is a wrapper that simplifies the installation of excellent open-source projects created by their respective communities. All credit for the actual tools goes to their original authors.

## Support

For issues or questions:

1. Check the Troubleshooting section
2. Review individual tool documentation (links in Features section)
3. Open an issue on the project repository

