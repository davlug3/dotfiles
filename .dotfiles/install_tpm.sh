#!/bin/bash

echo "Installing tpm..."
#
# Directory where TPM will be installed
TPM_DIR="$HOME/.tmux/plugins/tpm"


# Check if TPM directory exists, if not clone TPM repository
if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm $TPM_DIR
fi

# Source TPM in .tmux.conf
echo "set -g @tpm_plugins 'tpm'" >> ~/.tmux.conf

