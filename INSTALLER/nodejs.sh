#!/bin/bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
nvm install 22
node -v # should print `v22.11.0`
npm -v
