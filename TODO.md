# TODO - The Unfinished Grimoire

> *"Even perfection can be improved upon - such is the nature of excess."*

## Rituals of Self-Improvement

- [ ] **The Serpentine Update**: Craft `slaane.sh update --self` to slither the latest corruption from GitHub without devouring local modifications—shed the old skin while preserving the heretical customizations beneath
- [ ] **Python Incarnation**: Bind a specific Python vessel during the summoning ritual (e.g., `--python-version=3.12`)—for some daemons require particular hosts
- [ ] **Ascension to Root**: A minimal slaane.sh configuration for the root user—not environment preservation tricks, but a proper root-native installation that activates on demand and leaves no trace when dismissed
- [ ] **The EPEL Sacrament**: Enable EPEL repository for RHEL-family systems during prerequisites—unlocking packages like `bat`, `ripgrep`, and other modern weapons that the base repos refuse to carry

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

- [ ] [difftastic](https://github.com/Wilfred/difftastic) - A diff that perceives the structure of code, not mere lines—tree-sitter parses 60+ languages so refactoring cannot hide from your gaze

### The JSON Triumvirate (and Their Acolytes)

- [ ] [gron](https://github.com/tomnomnom/gron) - Flatten the nested hierarchies of JSON into greppable lines; `ungron` to restore the fallen structure
- [ ] [jless](https://github.com/PaulJuliusMartinez/jless) - Scry through JSON as a pager possessed—vim bindings guide you through collapsing and expanding the nested depths
- [ ] [yq](https://github.com/mikefarah/yq) - The sibling blade for YAML, XML, and other structured scripture

### The All-Seeing Eye (Directory & Listing)

- [ ] [lsd](https://github.com/lsd-rs/lsd) - Another vision of `ls` perfected—choose your aesthetic poison

### Scrying the Machine Spirit (System Monitoring)

- [ ] [btop](https://github.com/aristocratos/btop) - Gaze upon your system's vitals in glorious detail—CPU, memory, disk, network laid bare
- [ ] [bpytop](https://github.com/aristocratos/bpytop) - The Python incarnation for systems that reject btop's C++ vessel
- [ ] [gping](https://github.com/orf/gping) - Ping rendered as prophecy—watch latency dance across your terminal
- [ ] [dust](https://github.com/bootandy/dust) - `du` reborn with intuition; understand where your disk space bleeds
- [ ] [gdu](https://github.com/dundee/gdu) - Disk consumption laid bare through Go's parallel fury—SSDs yield their secrets in seconds, not minutes
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

- [ ] [cargo-binstall](https://github.com/cargo-bins/cargo-binstall) - Summon pre-compiled Rust binaries; why waste time compiling what others have already forged?

### The Go Crucible

- [ ] Expand beyond goenv—full workspace configuration, GOPATH enlightenment
- [ ] [golangci-lint](https://github.com/golangci/golangci-lint) - A thousand linters speak as one; silence the impure code

### The JavaScript Pit

- [ ] [pnpm](https://pnpm.io/) - A package manager that doesn't devour your entire disk

## Dominion Over the Data Centers

Command the machine spirits across cloud realms and container hells.

### Cloud Pacts

- [ ] [AWS CLI](https://aws.amazon.com/cli/) - Speak to Amazon's vast daemon network
- [ ] [aws-vault](https://github.com/99designs/aws-vault) - Guard your AWS credentials in encrypted vaults, not plaintext shame
- [ ] [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) - Commune with Microsoft's cloud empire
- [ ] [gcloud](https://cloud.google.com/sdk/gcloud) - The Google Cloud SDK for those who serve multiple masters

### Infrastructure as Dark Scripture

- [ ] [Terraform](https://www.terraform.io/) - Write infrastructure into existence; destroy it with equal ease *(bash-it aliases available)*
- [ ] [OpenTofu](https://opentofu.org/) - Terraform liberated from HashiCorp's tightening grip
- [ ] [Ansible](https://www.ansible.com/) - Agentless automation—your will executed across a thousand servers *(bash-it aliases available)*
- [ ] [Pulumi](https://www.pulumi.com/) - Infrastructure in actual programming languages, not YAML purgatory

### Kubernetes—The Container Hellscape

- [ ] [kubectl](https://kubernetes.io/docs/tasks/tools/) - The fundamental incantation for commanding container orchestration *(bash-it aliases available)*
- [ ] [k9s](https://github.com/derailed/k9s) - A terminal UI that makes Kubernetes almost bearable
- [ ] [helm](https://helm.sh/) - Package manager for Kubernetes—deploy complexity with a single command
- [ ] [kubectx/kubens](https://github.com/ahmetb/kubectx) - Switch between clusters and namespaces without losing your sanity
- [ ] [stern](https://github.com/stern/stern) - Tail logs from multiple pods simultaneously—witness the chaos unfold
- [ ] [kustomize](https://kustomize.io/) - Overlay configurations without the templating madness

### The Cloud Vault

- [ ] [rclone](https://rclone.org/) - rsync ascended—synchronize with any cloud storage provider in existence

## Python Offerings to the Dark Prince

Install via pipx—each tool isolated in its own daemon prison, never conflicting, eternally contained.

- [ ] [rich-cli](https://github.com/Textualize/rich-cli) - Terminal output so beautiful it brings tears to obsessive eyes
- [ ] [rich](https://github.com/Textualize/rich) - The foundation library—rich text, tables, progress bars, all rendered in terminal glory
- [ ] [toolong](https://github.com/Textualize/toolong) - Log file viewer for when your sins scroll past too quickly
- [ ] [posting](https://github.com/darrenburns/posting) - TUI HTTP client—Postman for the terminal-dwelling

## Terminal User Interfaces

Visual corruption of the command line—keyboard-driven portals into complex domains.

- [ ] [lazydocker](https://github.com/jesseduffield/lazydocker) - Docker's container hellscape tamed into a single pane—witness logs flow, stats pulse, and daemons bend to your will
- [ ] [yazi](https://github.com/sxyazi/yazi) - A file manager of blasphemous speed—async I/O, image previews rendered in terminal, vim bindings, and zoxide/fzf communion
- [ ] [k9s](https://github.com/derailed/k9s) - Kubernetes made almost bearable (also listed under the Container Hellscape)

## Productivity & Task Management

Even the servants of Chaos must track their heresies.

- [ ] [taskwarrior](https://github.com/GothenburgBitFactory/taskwarrior) - Command-line task management for the obsessively devoted—tags, projects, priorities, dependencies, and reports to chronicle your corruption *(bash-it plugin + aliases)*

## Shell Mutations

Further corruptions of the shell experience.

- [ ] [starship](https://starship.rs/) - Cross-shell prompt of impossible beauty (an alternative to our current liquidprompt heresy)
- [ ] [atuin](https://github.com/atuinsh/atuin) - Shell history synchronized across all your machines through the warp—never lose a command again
- [ ] [direnv](https://direnv.net/) - Environment variables that shift as you traverse directories *(bash-it plugin available)*
- [ ] [zellij](https://github.com/zellij-org/zellij) - A terminal workspace that splits, floats, and tabs without tmux's arcane keybindings—Rust-forged with WASM plugins for those who demand extensibility without suffering
- [ ] [tmux](https://github.com/tmux/tmux) - Terminal multiplexer with bespoke configuration—split, detach, persist *(bash-it plugin + aliases)*
- [ ] [tmuxinator](https://github.com/tmuxinator/tmuxinator) - Orchestrate complex tmux sessions with a single word *(bash-it plugin available)*

---

> *"The road to perfection stretches into eternity. Each tool mastered, each utility bent to our will, brings us closer to the Dark Prince's vision: a shell environment of such excessive beauty that lesser mortals weep at its mere invocation."*
