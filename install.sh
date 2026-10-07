#!/usr/bin/env bash

set -e

have() { command -v "$1" >/dev/null 2>&1; }

# Single source of truth for package installs lives in installers/.
# Runs installers/<name>.sh from the local clone when present,
# otherwise fetches it from GitHub (curl-pipe bootstrap mode).
# Set DOTFILES_REF to a branch, tag, or commit SHA to pin installers
# to the same ref as the outer script (bypasses main CDN cache).
: "${DOTFILES_REF:=main}"
REPO_RAW="https://raw.githubusercontent.com/davlug3/dotfiles/${DOTFILES_REF}/installers"
run_installer() {
    local name="$1"
    if [ -f "$PWD/installers/${name}.sh" ]; then
        bash "$PWD/installers/${name}.sh"
    elif have curl; then
        curl -fsSL "${REPO_RAW}/${name}.sh" | bash
    elif have wget; then
        wget -qO- "${REPO_RAW}/${name}.sh" | bash
    else
        echo "error: need curl or wget to fetch ${name} installer" >&2
        exit 1
    fi
}

# Install a system package using the first available package manager.
# Bootstrap-only helper (used for git); package installs live in installers/.
_pkg_install() {
    if have pkg; then          pkg install -y "$1"
    elif have apt-get; then    sudo apt-get update && sudo apt-get install -y "$1"
    elif have dnf; then        sudo dnf install -y "$1"
    elif have pacman; then     sudo pacman -S --noconfirm --needed "$1"
    elif have brew; then       brew install "$1"
    else
        echo "error: no supported package manager to install $1" >&2
        echo "Please install $1 manually, then re-run." >&2
        return 1
    fi
}

install_neovim() {
    echo ">>> ensuring neovim..."
    run_installer install-nvim
}


install_starship() {
    echo ">>> ensuring starship..."
    run_installer install-starship
}

# Ensure prerequisites for a brand-new machine are present:
#   * git      — required by chezmoi to initialize from the repo
#   * starship — referenced by .bashrc / .bashrc.termux (`starship init bash`)
# No-ops when the tools are already installed.
install_dependencies() {
    if ! have git; then
        echo ">>> git not found; installing..."
        _pkg_install git || exit 1
        have git || { echo "error: git was not installed" >&2; exit 1; }
    fi

    install_starship
    install_neovim
}

print_banner() {
echo "    _____  _____  __ __  ____   __ __  _____  _____  "
echo "   |  _  \/  _  \/  |  \/  _/  /  |  \/   __\/  _  \ "
echo "   |  |  ||  _  |\  |  /|  |---|  |  ||  |_ |>-<_  < "
echo "   |_____/\__|__/ \___/ \_____/\_____/\_____/\_____/ "

echo "  installing dotfiles..."
echo ""
}

install_chezmoi() {
    if have chezmoi; then
        echo "chezmoi already installed"
        return
    fi

    if have curl; then
        sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
    elif have wget; then
        sh -c "$(wget -qO- https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
    else
        echo "error: need curl or wget to install chezmoi" >&2
        exit 1
    fi
}

main() {
    local local_repo=false
    [ -f "$PWD/install.sh" ] && local_repo=true

    print_banner

    # Ensure $HOME/.local/bin exists for both starship and chezmoi installers
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"

    install_dependencies
    install_chezmoi

    if $local_repo; then
        if [ ! -d "$HOME/.local/share/chezmoi" ]; then
            chezmoi init --apply "$PWD"
        else
            chezmoi apply  # re-apply current source state (idempotent update)
        fi
    else
        chezmoi init --apply davlug3/dotfiles
    fi

    echo ""
    echo "done! dotfiles applied."
}

main "$@"
