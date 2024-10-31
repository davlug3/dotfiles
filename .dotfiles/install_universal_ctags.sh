#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


REPO_URL="https://github.com/universal-ctags/ctags.git"
CLONE_DIR="$SCRIPT_DIR/tmp/ctags"
INSTALL_DIR="$SCRIPT_DIR/tmp/ctags_install"

echo $REPO_URL
echo $CLONE_DIR
echo $INSTALL_DIR



# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install missing packages
install_packages() {
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y autotools-dev autoconf make gcc
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y autoconf automake make gcc
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y autoconf automake make gcc
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Syu --noconfirm autoconf automake make gcc
    else
        echo "Unsupported package manager. Please install autotools, autoconf, make, and gcc manually."
        exit 1
    fi
}

# Function to clean up installed packages or created files
cleanup() {
    echo "Cleaning up..."
    if [ -d "$INSTALL_DIR" ]; then
        sudo rm -rf "$INSTALL_DIR"
        echo "Removed $INSTALL_DIR"
    fi
    if [ -d "$CLONE_DIR" ]; then
        rm -rf "$CLONE_DIR"
        echo "Removed $CLONE_DIR"
    fi

   if [ -d "$SCRIPT_DIR/tmp" ] && [ -z "$(ls -A $SCRIPT_DIR/tmp)" ]; then
        echo "$SCRIPT_DIR/tmp is empty. Deleting..."
        sudo rmdir $SCRIPT_DIR/tmp
    else
        echo "$SCRIPT_DIR/tmp is not empty or does not exist."
    fi
}

# Trap to handle errors and cleanup
trap 'cleanup; exit 1;' ERR

# Check for required packages and prompt user to install if missing
missing_packages=()
for pkg in autotools autoconf make gcc; do
    if ! command_exists $pkg; then
        missing_packages+=($pkg)
    fi
done

if [ ${#missing_packages[@]} -ne 0 ]; then
    echo "The following required packages are missing: ${missing_packages[@]}"
    read -p "Do you want to install them now? (y/n) " answer
    case $answer in
        [Yy]* )
            echo "Installing missing packages..."
            install_packages
            ;;
        [Nn]* )
            echo "Installation aborted. Please install the missing packages manually."
            exit 1
            ;;
        * )
            echo "Invalid response. Please answer 'y' or 'n'."
            exit 1
            ;;
    esac
fi

# Clone the repository
git clone "$REPO_URL" "$CLONE_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone the repository."
    cleanup
    exit 1
fi

cd "$CLONE_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to change directory to $CLONE_DIR."
    cleanup
    exit 1
fi

# Run autogen.sh
./autogen.sh
if [ $? -ne 0 ]; then
    echo "Error: autogen.sh failed."
    cleanup
    exit 1
fi

# Configure the build
./configure  # Add --prefix=/where/you/want if needed
if [ $? -ne 0 ]; then
    echo "Error: configure script failed."
    cleanup
    exit 1
fi

# Build the project
make
if [ $? -ne 0 ]; then
    echo "Error: make failed."
    cleanup
    exit 1
fi

# Install the build
sudo make install
if [ $? -ne 0 ]; then
    echo "Error: make install failed."
    cleanup
    exit 1
fi

echo "Installation completed successfully."

# Clean up
cleanup

