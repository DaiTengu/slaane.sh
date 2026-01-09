# TODO - The Unfinished Grimoire

> *"Even perfection can be improved upon - such is the nature of excess."*

## Rituals of Self-Improvement

- [ ] **The Serpentine Update**: Craft `slaane.sh update --self` to slither the latest corruption from GitHub without devouring local modifications—shed the old skin while preserving the heretical customizations beneath
- [ ] **Python Incarnation**: Bind a specific Python vessel during the summoning ritual (e.g., `--python-version=3.12`)—for some daemons require particular hosts

## The Proving Grounds

Docker containers are hollow vessels—minimal, sterile, lacking the chaos of real systems. True validation requires flesh and blood machines.

- [ ] **AWS Summoning Circles**: Spin up EC2 instances on-demand for realistic testing—per-second billing means the sacrifice is measured in pennies, not gold
  - Rocky/Alma Linux (RHEL bloodline)
  - Ubuntu/Debian (the hive worlds)
  - Arch Linux (chaos undivided)
  - Gentoo (the truly damned)
- [ ] **The Automated Inquisition**: GitHub Actions pipeline to torment every commit—the Machine Spirit shall validate all changes before they corrupt the masses
- [ ] **test-aws.sh**: A script to conjure instances, deploy the corruption, verify the transformation, and banish the vessels back to the void
- [ ] **Multi-Architecture Trials**: Test across x86_64 and aarch64 (ARM)—the corruption must spread to all machine spirits

## Terminal Sorcery

Modern weapons to replace the rusted Imperial utilities. All shall be bound to the user's personal domain (`~/.local/bin`, `~/.cargo/bin`) rather than defiling the system temples—unless the system already bears their mark.

### Blades of Text & File

- [ ] [bat](https://github.com/sharkdp/bat) - A `cat` reborn with syntax highlighting—witness your files shimmer with unholy colors
- [ ] [jq](https://github.com/jqlang/jq) - Interrogate JSON with surgical precision; extract confessions from any API
- [ ] [yq](https://github.com/mikefarah/yq) - The sibling blade for YAML, XML, and other structured scripture
- [ ] [ripgrep](https://github.com/BurntSushi/ripgrep) - Grep reforged in the warp—blazingly fast, respects no boundary
- [ ] [fd](https://github.com/sharkdp/fd) - The `find` command freed from its decrepit Imperial syntax

### The All-Seeing Eye (Directory & Listing)

- [ ] [eza](https://github.com/eza-community/eza) - `ls` ascended—colors, icons, Git awareness; the successor to the fallen exa
- [ ] [lsd](https://github.com/lsd-rs/lsd) - Another vision of `ls` perfected—choose your aesthetic poison

### Scrying the Machine Spirit (System Monitoring)

- [ ] [btop](https://github.com/aristocratos/btop) - Gaze upon your system's vitals in glorious detail—CPU, memory, disk, network laid bare
- [ ] [bpytop](https://github.com/aristocratos/bpytop) - The Python incarnation for systems that reject btop's C++ vessel
- [ ] [gping](https://github.com/orf/gping) - Ping rendered as prophecy—watch latency dance across your terminal
- [ ] [dust](https://github.com/bootandy/dust) - `du` reborn with intuition; understand where your disk space bleeds
- [ ] [duf](https://github.com/muesli/duf) - `df` made beautiful; survey your storage domains at a glance

### Tendrils Across the Warp (Network Tools)

- [ ] [dog](https://github.com/ogham/dog) - DNS divination without `dig`'s baroque Imperial syntax
- [ ] [httpie](https://github.com/httpie/cli) - Speak to APIs as mortals speak to each other—not in curl's ancient machine tongue
- [ ] [curlie](https://github.com/rs/curlie) - For those who still require curl's dark power but crave httpie's grace

### Instruments of Creation (Text Editors)

- [ ] [Fresh](https://github.com/sinelaw/fresh) - A terminal editor forged in Rust—fast, beautiful, modern (requires the Rust toolchain)
- [ ] **Vim Ascension** - The One True Editor with custom incantations, plugins, and keybindings tailored to the devoted

## Language Forges

Version managers and toolchains bound to user space—no sudo required, no system defiled.

### The Rust Forge

- [ ] [rustup](https://rustup.rs/) - The canonical path to Rust—required for Fresh and other Rust-forged weapons
- [ ] [cargo-binstall](https://github.com/cargo-bins/cargo-binstall) - Summon pre-compiled Rust binaries; why waste time compiling what others have already forged?

### The Go Crucible

- [ ] Expand beyond goenv—full workspace configuration, GOPATH enlightenment
- [ ] [golangci-lint](https://github.com/golangci/golangci-lint) - A thousand linters speak as one; silence the impure code

### The JavaScript Pit

- [ ] [nvm](https://github.com/nvm-sh/nvm) - Node Version Manager—because JavaScript's chaos spawns new versions endlessly
- [ ] [pnpm](https://pnpm.io/) - A package manager that doesn't devour your entire disk

## Dominion Over the Data Centers

Command the machine spirits across cloud realms and container hells.

### Cloud Pacts

- [ ] [AWS CLI](https://aws.amazon.com/cli/) - Speak to Amazon's vast daemon network
- [ ] [aws-vault](https://github.com/99designs/aws-vault) - Guard your AWS credentials in encrypted vaults, not plaintext shame
- [ ] [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) - Commune with Microsoft's cloud empire
- [ ] [gcloud](https://cloud.google.com/sdk/gcloud) - The Google Cloud SDK for those who serve multiple masters

### Infrastructure as Dark Scripture

- [ ] [Terraform](https://www.terraform.io/) - Write infrastructure into existence; destroy it with equal ease
- [ ] [OpenTofu](https://opentofu.org/) - Terraform liberated from HashiCorp's tightening grip
- [ ] [Ansible](https://www.ansible.com/) - Agentless automation—your will executed across a thousand servers
- [ ] [Pulumi](https://www.pulumi.com/) - Infrastructure in actual programming languages, not YAML purgatory

### Kubernetes—The Container Hellscape

- [ ] [kubectl](https://kubernetes.io/docs/tasks/tools/) - The fundamental incantation for commanding container orchestration
- [ ] [k9s](https://github.com/derailed/k9s) - A terminal UI that makes Kubernetes almost bearable
- [ ] [helm](https://helm.sh/) - Package manager for Kubernetes—deploy complexity with a single command
- [ ] [kubectx/kubens](https://github.com/ahmetb/kubectx) - Switch between clusters and namespaces without losing your sanity
- [ ] [stern](https://github.com/stern/stern) - Tail logs from multiple pods simultaneously—witness the chaos unfold
- [ ] [kustomize](https://kustomize.io/) - Overlay configurations without the templating madness

### The Cloud Vault

- [ ] [rclone](https://rclone.org/) - rsync ascended—synchronize with any cloud storage provider in existence

## Python Offerings to the Dark Prince

Install via pipx—each tool isolated in its own daemon prison, never conflicting, eternally contained.

- [ ] [pipx](https://github.com/pypa/pipx) - The vessel for isolated Python tool installation
- [ ] [rich-cli](https://github.com/Textualize/rich-cli) - Terminal output so beautiful it brings tears to obsessive eyes
- [ ] [rich](https://github.com/Textualize/rich) - The foundation library—rich text, tables, progress bars, all rendered in terminal glory
- [ ] [toolong](https://github.com/Textualize/toolong) - Log file viewer for when your sins scroll past too quickly
- [ ] [posting](https://github.com/darrenburns/posting) - TUI HTTP client—Postman for the terminal-dwelling

## Shell Mutations

Further corruptions of the shell experience.

- [ ] [starship](https://starship.rs/) - Cross-shell prompt of impossible beauty (an alternative to our current liquidprompt heresy)
- [ ] [atuin](https://github.com/atuinsh/atuin) - Shell history synchronized across all your machines through the warp—never lose a command again
- [ ] [direnv](https://direnv.net/) - Environment variables that shift as you traverse directories
- [ ] [tmux](https://github.com/tmux/tmux) - Terminal multiplexer with bespoke configuration—split, detach, persist
- [ ] [tmuxinator](https://github.com/tmuxinator/tmuxinator) - Orchestrate complex tmux sessions with a single word

---

> *"The road to perfection stretches into eternity. Each tool mastered, each utility bent to our will, brings us closer to the Dark Prince's vision: a shell environment of such excessive beauty that lesser mortals weep at its mere invocation."*
