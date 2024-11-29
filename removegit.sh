#!/bin/bash
# File to be parsed

if [ ! -e $0/.env ]; then
    echo "$0/.env does not exist. Is the dotfiles script set up?"
    exit 1
fi

echo "Sourcing $0/.env..."
source $0/.env
echo "Done."

cd $HOME;
git -C $HOME checkout $(git rev-list --max-parents=0 HEAD)
echo "done restoring files."

echo "removing $HOME/.git"
rm -rf $HOME/.git

if [[ -e "$HOME/.git.backup" ]]; then
    echo "$HOME/.git.backup detected. Moving to $HOME/.git..."
    mv $HOME/.git.backup $HOME/.git
fi

echo "Successfully restored to original state."
exit 0
