#!/usr/bin/env bash
# nvm - Node Version Manager

MODULE_BIN=""  # nvm is a shell function, not a binary
MODULE_DIR="$HOME/.nvm"
MODULE_CHECK_FILE="$HOME/.nvm/nvm.sh"
MODULE_BASHIT_PLUGIN="nvm"
MODULE_PROJECT_URL="https://github.com/nvm-sh/nvm"

# nvm has its own installer - doesn't use dra
install() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
}

# Custom check since nvm is a shell function
is_installed() {
    [[ -f "$HOME/.nvm/nvm.sh" ]]
}

# Custom update
update() {
    if [[ -d "$HOME/.nvm/.git" ]]; then
        (cd "$HOME/.nvm" && git fetch --tags origin && git checkout "$(git describe --abbrev=0 --tags --match 'v[0-9]*' "$(git rev-list --tags --max-count=1)")")
    else
        # Re-run installer to update
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
}
