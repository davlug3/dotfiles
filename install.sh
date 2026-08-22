#!/usr/bin/env bash

set -e

have() { command -v "$1" >/dev/null 2>&1; }

# Install a system package using the first available package manager.
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

    if ! have starship; then
        echo ">>> starship not found; installing to \$HOME/.local/bin..."
        if have curl; then
            curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
        elif have wget; then
            wget -qO- https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
        else
            echo "error: need curl or wget to install starship" >&2
            exit 1
        fi
        [ -x "$HOME/.local/bin/starship" ] || {
            echo "error: starship was not installed" >&2; exit 1;
        }
    fi
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

    install_dependencies
    install_chezmoi

    export PATH="$HOME/.local/bin:$PATH"

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
