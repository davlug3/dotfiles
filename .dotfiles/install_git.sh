#!/bin/bash


command_exists() {
    command -v "$1" >/dev/null 2>&1
}


if command_exists git; then
echo "Git is already installed."
git --version
exit 0
fi

echo "Installing Git..."

if command_exists apt; then
sudo apt update
sudo apt install -y git

elif command_exists dnf; then
sudo dnf install -y git

elif command_exists yum; then
sudo yum install -y git

elif command_exists pacman; then
sudo pacman -Sy --noconfirm git

elif command_exists zypper; then
sudo zypper install -y git

elif command_exists apk; then
sudo apk add git

else
echo "Error: Unable to identify package manager."
echo "Please install Git manually."
exit 1
fi

if command_exists git; then
echo "Git successfully installed."
git --version
else
echo "Git installation failed."
exit 1
fi
