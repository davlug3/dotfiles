#!/usr/bin/env bash

set -e

echo "installing vim-plug..."
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "running PlugInstall..."
vim -E -s -c "PlugInstall --sync" -c "qa" 2>/dev/null || true

echo "plugin installation done"
