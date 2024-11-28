#!/bin/bash
# File to be parsed


cd $HOME;
git checkout $(git rev-list --max-parents=0 HEAD)
echo "done restoring files."

echo "removing $HOME/.git"
rm -rf $HOME/.git

if [[ -e "$HOME/.git.backup" ]]
    echo "$HOME/.git.backup detected. Moving to $HOME/.git..."
    mv $HOME/.git.backup $HOME/.git
fi

echo "Successfully restored to original state."
exit 0
