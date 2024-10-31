#!/bin/bash

echo "installing tmux..."
install_tmux_pkg() {
    case "$1" in
        "apt")
            sudo apt update
            sudo apt install -y tmux
            ;;
        "yum")
            sudo yum install -y epel-release
            sudo yum install -y tmux
            ;;
        "dnf")
            sudo dnf install -y tmux
            ;;
        "pacman")
            sudo pacman -Syu tmux
            ;;
        *)
            echo "Unsupported package manager: $1"
            echo "Attempting to install from source."
            install_tmux_source
            ;;
    esac
}

install_tmux_source() {
    sudo apt update || sudo yum install -y gcc make pkg-config libevent-dev libncurses5-dev libncursesw5-dev

    TMUX_VERSION=$(curl -s https://api.github.com/repos/tmux/tmux/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    echo "Installing tmux $TMUX_VERSION"

    git clone https://github.com/tmux/tmux.git
    cd tmux
    git checkout "$TMUX_VERSION"

    sh autogen.sh
    ./configure
    make
    sudo make install

    cd ..
    rm -rf tmux
}

# Detect the package manager
if command -v apt &> /dev/null; then
    install_tmux_pkg "apt"
elif command -v yum &> /dev/null; then
    install_tmux_pkg "yum"
elif command -v dnf &> /dev/null; then
    install_tmux_pkg "dnf"
elif command -v pacman &> /dev/null; then
    install_tmux_pkg "pacman"
else
    echo "No supported package manager found. Please install tmux manually."
    exit 1
fi

echo "tmux installation complete!"

