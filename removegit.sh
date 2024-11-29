#!/bin/bash
# File to be parsed

SCRIPT_DIR=$(dirname "$0")

if [ ! -e "$SCRIPT_DIR/.env" ]; then
    echo "$SCRIPT_DIR/.env does not exist. Is the dotfiles script set up?"
    exit 1
fi

echo "Sourcing $0/.env..."
source $SCRIPT_DIR/.env
echo "Done."

cd $HOME;
$DDOTFILES_GIT_BIN -C $HOME checkout $($DDOTFILES_GIT_BIN -C $HOME rev-list --max-parents=0 HEAD)
echo "done restoring files$DDOTFILES_GIT_BIN

echo "removing $HOME/.git"
rm -rf $HOME/.git

if [[ -e "$HOME/.git.backup" ]]; then
    echo "$HOME/.git.backup detected. Moving to $HOME/.git..."
    mv $HOME/.git.backup $HOME/.git
fi

echo "Successfully restored to original state."
exit 0
