# Slaane.sh

> *"Excess in all things - especially shell configuration"*

A portable bash environment installer touched by the Dark Prince. Deploy your meticulously crafted shell across the Imperium's countless server worlds, from the forge worlds of RHEL to the hive cities of Debian.

**⚠️ Manifesto:** This unholy creation was wrought entirely by cogitators (AI-assisted development). The Machine Spirit has been consulted, and it is pleased.

## The Gifts of Slaanesh

Your shell environment, perfected through obsessive customization, deserves to follow you across every server you touch. This installer delivers:

### Core Blessings

- **[bash-it](https://github.com/Bash-it/bash-it)** - The framework that binds all
- **[ble.sh](https://github.com/akinomyoga/ble.sh)** - Syntax highlighting that makes your terminal weep with beauty
  - Auto-suggestions whispered from the warp
  - Vim modes for the initiated
  - Enhanced completion beyond mortal comprehension
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finding through the immaterium of your command history
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Instant teleportation between directories
- **[pyenv](https://github.com/pyenv/pyenv)** - Python version sorcery
- **[goenv](https://github.com/go-nv/goenv)** - Go version manipulation
- **[thefuck](https://github.com/nvbn/thefuck)** - Command correction through sheer indignation
- **[nano-syntax-highlighting](https://github.com/galenguyer/nano-syntax-highlighting)** - Syntax highlighting for the nano editor (for those who embrace heresy over vim)

### Optional Temptations

- **[bashhub](https://bashhub.com)** - Command history stored in the cloud (requires ritual authentication)

## Ritual of Installation

### The Quick Path

```bash
# Summon the repository
git clone https://github.com/DaiTengu/slaane.sh.git ~/slaane.sh
cd ~/slaane.sh

# Invoke the installer
./install.sh
```

### After Installation

```bash
# Awaken the new environment
source ~/.bashrc

# Or begin anew
exec bash
```

## Invocations (Installation Options)

### Standard Corruption

Installs all core components:

```bash
./install.sh
```

### Minimal Devotion

Only bash-it, ble.sh, and fzf - for the newly converted:

```bash
./install.sh --minimal
```

### Skip Certain Gifts

```bash
# Reject goenv and thefuck
./install.sh --skip=goenv,thefuck
```

### Embrace Bashhub

```bash
./install.sh --with-bashhub
```

### Auto-Install Prerequisites

Allow the installer to claim dominion over missing tools:

```bash
./install.sh --install-prereqs
```

### Force Reinstallation

Purge and rebuild:

```bash
./install.sh --force
```

## Prerequisites

The installer demands these tools be present (or will install them with `--install-prereqs`):

- `git` - To pull from the repository vaults
- `curl` - To reach across the network
- `make` - To build from source
- `gawk` - GNU Awk, required by ble.sh
- C compiler (`gcc` or build tools)

### Manual Prerequisites Installation

**Debian/Ubuntu (Hive Worlds):**
```bash
sudo apt-get update && sudo apt-get install -y git curl make build-essential gawk
```

**RHEL/CentOS/Fedora/Rocky (Forge Worlds):**
```bash
sudo dnf install -y git curl make gcc gcc-c++ gawk
```

**Arch Linux (Chaos Undivided):**
```bash
sudo pacman -S git curl make base-devel gawk
```

Or submit to the installer's will:
```bash
./install.sh --install-prereqs
```

## Spreading the Corruption (Deployment)

### Method 1: Tarball Transference

```bash
# Package the corruption
cd ~
tar czf slaane.sh.tar.gz slaane.sh/

# Transfer to remote server
scp slaane.sh.tar.gz user@remote:~/

# On the remote server
ssh user@remote
tar xzf slaane.sh.tar.gz
cd slaane.sh
./install.sh
```

### Method 2: Direct Summoning

```bash
ssh user@remote
git clone https://github.com/DaiTengu/slaane.sh.git ~/slaane.sh
cd ~/slaane.sh
./install.sh
```

### Method 3: The Forbidden Script

```bash
ssh user@remote
curl -fsSL https://raw.githubusercontent.com/DaiTengu/slaane.sh/master/install.sh | bash -s -- --install-prereqs
```

## Configuration Rituals

### Sacred Texts

- **`~/.bashrc`** - The primary grimoire (installed from `config/bashrc.template`)
- **`~/.blerc`** - ble.sh incantations (1307 lines of obsessive configuration)
- **`~/.bashrc.local`** - Your personal heresies (not overwritten)

### Customizing the Blessing

Edit `config/bash-it-components` to modify which bash-it components are enabled:

```bash
# config/bash-it-components
[alias]
git
docker
# ... your preferences

[plugin]
git
fzf
# ... your preferences

[completion]
git
docker
# ... your preferences
```

**Heretical Modification:** The installer corrupts bash-it's default `liquidprompt.theme.bash`, replacing it with a corrected version that properly manifests git branch names in the prompt. The original theme's `_lp_git_branch()` function failed to bind the branch variable, leaving only status symbols visible to the uninitiated.

### Local Customization

Create `~/.bashrc.local` for server-specific incantations:

```bash
# ~/.bashrc.local
export HERESY="acceptable"
alias my_ritual='echo "The Emperor protects... from bad shell configs"'
```

## Wielding Your New Power

### Key Features

#### Syntax Highlighting (ble.sh)
Watch as your commands shimmer with color, distinguishing the valid from the profane.

#### Auto-Suggestions (ble.sh)
The shell whispers completions from your history. Press `Shift+Right` to accept its counsel.

#### Fuzzy Finding (fzf)
- **`Ctrl+R`** - Dive into the warp of command history
- **`Ctrl+T`** - Summon files from the void
- **`Alt+C`** - Teleport between directories

#### Smart Directory Jumping (zoxide)
```bash
# Jump to frequently visited realms
z documents
z my-project
z ~

# Survey your domains
zoxide query -l
```

#### Python Version Mastery (pyenv)
```bash
# List available Python versions
pyenv install --list

# Install a specific version
pyenv install 3.11.0

# Set your global Python
pyenv global 3.11.0

# Set project-specific Python
cd my-project
pyenv local 3.9.0
```

#### Go Version Control (goenv)
```bash
# List available Go versions
goenv install --list

# Install a version
goenv install 1.21.0

# Set global version
goenv global 1.21.0
```

#### Command Correction (thefuck)
When you inevitably stumble:

```bash
$ gti status
$ fuck
# Corrects to: git status
```

#### Nano Syntax Highlighting
For the heretics who prefer nano over vim, syntax highlighting is automatically installed:

```bash
# Open any file and witness syntax highlighting
nano script.sh
nano config.yaml
nano Dockerfile

# The highlighting works automatically - no configuration needed
# Files are installed to ~/.nano/
```

**Note:** If nano is not installed, the syntax files are still installed and will activate once nano is installed. Use `--install-prereqs` to automatically install nano during setup.

## Architecture Support

The installer adapts to your machine's architecture like a daemon to its host:

- **x86_64** (Standard Imperial)
- **aarch64** (ARM 64-bit - Adeptus Mechanicus approved)
- **armv7l** (ARM 32-bit)
- Other architectures (falls back to source compilation)

## Distribution Support

Tested across the following Imperial/Chaos sectors:

- **Debian/Ubuntu** - Hive worlds (apt)
- **RHEL/CentOS/Fedora/Rocky/AlmaLinux** - Forge worlds (dnf/yum)
- **Arch Linux** - Chaos undivided (pacman)
- **Gentoo** - The truly damned (emerge)

Auto-detects your distribution and package manager. The Omnissiah provides.

## Troubleshooting Possession Issues

### Prerequisites Missing

If the installer balks at missing tools:

```bash
# Option 1: Manual propitiation
# (see Prerequisites section above)

# Option 2: Let the installer claim what it needs
./install.sh --install-prereqs
```

### ble.sh Refuses to Manifest

Ensure bash-it loads properly and the blesh plugin is enabled:

```bash
bash-it enable plugin blesh
source ~/.bashrc
```

### fzf Integration Broken

Integration with ble.sh flows through bash-it's blesh plugin. Verify both are enabled:

```bash
bash-it show plugin | grep -E "(fzf|blesh)"
```

### pyenv Build Failures

The forge requires proper materials. Install build dependencies:

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

### zoxide Missing on RHEL Systems

The installer auto-enables EPEL. If it fails, manually enable:

```bash
sudo dnf install -y epel-release
sudo dnf install -y zoxide
```

### Verification Incantations

```bash
# Survey bash-it's domain
bash-it show aliases
bash-it show plugins
bash-it show completions

# Check the ble.sh possession
echo $BLE_VERSION

# Verify the other tools
fzf --version
zoxide --version
pyenv --version
goenv --version
thefuck --version

# Check nano syntax highlighting (for the heretics)
ls ~/.nano/*.nanorc 2>/dev/null | wc -l  # Count of syntax files
```

## Project Structure

```
slaane.sh/
├── install.sh              # The primary ritual
├── lib/
│   └── common.sh          # Common incantations (OS detection, logging)
├── modules/
│   ├── 00-prereqs.sh      # Prerequisites guardian
│   ├── 10-bash-it.sh      # bash-it summoner
│   ├── 20-blesh.sh        # ble.sh manifestation
│   ├── 30-fzf.sh          # fzf invocation
│   ├── 40-zoxide.sh       # zoxide conjuration
│   ├── 50-pyenv.sh        # pyenv binding
│   ├── 60-goenv.sh        # goenv rite
│   ├── 70-thefuck.sh      # thefuck channeling
│   ├── 80-nano.sh         # nano syntax highlighting (for heretics)
│   └── 90-bashhub.sh      # bashhub pact (optional)
├── config/
│   ├── bashrc.template        # Template grimoire
│   ├── blerc                  # ble.sh tome (1307 lines of perfection)
│   ├── bash-it-components     # List of enabled blessings
│   └── liquidprompt.theme.bash # Corrupted liquidprompt theme (replaces broken default)
├── test.sh                # Verification ritual
├── test-docker.sh         # Multi-realm testing
├── TESTING.md             # Testing doctrine
└── README.md              # This scripture
```

## Banishment (Uninstallation)

To purge Slaane.sh from your system:

```bash
# Restore your original shell
cp ~/.bashrc.pre-slaanesh ~/.bashrc

# Remove the gifts
rm -rf ~/.bash_it
rm -rf ~/.local/share/blesh
rm -rf ~/.fzf
rm -rf ~/.pyenv
rm -rf ~/.goenv
rm -f ~/.blerc

# Uninstall pip/cargo packages if desired
pip3 uninstall thefuck
```

## Testing the Installation

See [TESTING.md](TESTING.md) for the complete testing doctrine.

Quick verification on Rocky Linux 9:
```bash
./test-docker.sh --distro rockylinux:9
```

Tested and verified across 5 distributions:
- ✅ Rocky Linux 9 (22/23 tests)
- ✅ Ubuntu 22.04 (22/23 tests)
- ✅ Fedora 39 (22/23 tests)
- ✅ Debian 12 (21/23 tests)
- ✅ Arch Linux (22/23 tests)

## Contributing

This is a personal configuration, but if you wish to submit offerings:

- Report bugs
- Suggest improvements
- Submit pull requests
- Share your own heresies

## License

This project orchestrates the installation of various open-source tools, each bound by their own licenses:

- bash-it: MIT
- ble.sh: BSD-3-Clause
- fzf: MIT
- zoxide: MIT
- pyenv: MIT
- goenv: MIT
- thefuck: MIT

## Acknowledgments

All glory to the original creators of these magnificent tools. This installer merely serves as a conduit for their power.

Special thanks to:
- The Machine Spirit for guidance
- Claude (Cogitator-class AI) for manifestation of this code
- The Chaos Gods for inspiration

## Warning

> *"To comprehend the true nature of this shell configuration is to court madness. The initiated know that perfection of one's terminal environment is a path from which there is no return."*

For issues, questions, or to report possession by rogue shell scripts:
- Open an issue: https://github.com/DaiTengu/slaane.sh/issues
- Check TESTING.md for verification rituals
- Consult the individual tool documentation for deeper mysteries

---

**The Emperor Protects… but Slaane.sh Perfects.**
