#!/bin/bash

GIT_BIN=/usr/bin/git
DOTFILES_GIT_URL=~/dotfiles
DOTFILES_HOME=$HOME/.ddconfig
SEPARATE_GIT_DIR=$HOME/.ddgit
SEPARATE_GIT_IGNORE=$HOME/.ddgitignore

git init --separate-git-dir=$SEPARATE_GIT_DIR $HOME
git config --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME core.excludesFile $SEPARATE_GIT_IGNORE
touch $SEPARATE_GIT_IGNORE
echo * >> $SEPARATE_GIT_IGNORE


$GIT_BIN clone "$DOTFILES_GIT_URL" "$DOTFILES_HOME" && echo "git clone succeeded." || { echo "git clone failed. Exiting..."; exit 1; }


loop() {
    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME add --force "$HOME/$filename"
    done
    git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME commit -m "Initial commits"

    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        rm -rf -- $HOME/$filename
        ln -s "$DOTFILES_HOME/LINK_TO_HOME/$1" "$HOME/$1"
        git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME add --force "$HOME/$filename"

    done
    git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME commit -m "Second commit"

}
