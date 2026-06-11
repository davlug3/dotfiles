#!/usr/bin/env bash

set -e

print_banner() {
echo "    _____  _____  __ __  ____   __ __  _____  _____  "
echo "   |  _  \/  _  \/  |  \/  _/  /  |  \/   __\/  _  \ "
echo "   |  |  ||  _  |\  |  /|  |---|  |  ||  |_ |>-<_  < "
echo "   |_____/\__|__/ \___/ \_____/\_____/\_____/\_____/ "

echo "  installing dotfiles..."
echo ""
}

install_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        echo "chezmoi already installed"
        return
    fi

    if command -v curl >/dev/null 2>&1; then
        sh -c "$(curl -fsSL https://chezmoi.io/get)"
    elif command -v wget >/dev/null 2>&1; then
        sh -c "$(wget -qO- https://chezmoi.io/get)"
    else
        echo "error: need curl or wget to install chezmoi" >&2
        exit 1
    fi
}

main() {
    local local_repo=false
    [ -f "$PWD/install.sh" ] && local_repo=true

    print_banner

    install_chezmoi

    if $local_repo; then
        if [ ! -d "$HOME/.local/share/chezmoi" ]; then
            chezmoi init --apply "$PWD"
        else
            chezmoi reapply
        fi
    else
        chezmoi init --apply davlug3/dotfiles
    fi

    echo ""
    echo "done! dotfiles applied."
}

main "$@"
