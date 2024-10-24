#!/bin/bash


echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

export NVM_DIR="${HOME}/.nvm"


#load nvm
[ -s  "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "NVM installed and initialized"


echo "Installing Node.js 22..."
nvm install 22

echo "Verifying installation..."
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

echo "Installed Node.js version: $NODE_VERSION"
echo "Installed NPM version: $NPM_VERSION"

