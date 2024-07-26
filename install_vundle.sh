#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "Script directory $SCRIPT_DIR"

cd $SCRIPT_DIR || exit


git submodule add \
   https://github.com/VundleVim/Vundle.vim.git \
   $SCRIPT_DIR/vim/.vim/bundle/Vundle.vim

echo "Vundle installed..."
exit 0

