#!/bin/bash

GIT_BIN=/usr/bin/git
DOTFILES_GIT_URL=/dotfiles
DOTFILES_HOME=$HOME/.ddconfig
SEPARATE_GIT_DIR=$HOME/.ddgit
SEPARATE_GIT_IGNORE=$HOME/.ddgitignore

if [[ -e $HOME/.git ]]; then
    echo ".git directory exists. moving to $HOME/.git.backup"
    mv $HOME/.git $HOME/.git.backup
    echo "done"
fi


cd $HOME
git init $HOME
git config core.excludesFile $SEPARATE_GIT_IGNORE
touch $SEPARATE_GIT_IGNORE
echo * >> $SEPARATE_GIT_IGNORE

$GIT_BIN clone --branch new "$DOTFILES_GIT_URL" "$DOTFILES_HOME" && echo "git clone succeeded." || { echo "git clone failed. Exiting..."; exit 1; }


loop() {
    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
	if [[ -e "$HOME/$filename" ]]; then
		echo git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME add --force "$HOME/$filename"
		git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME add --force "$HOME/$filename"
	fi
    done
    echo "done1"

    git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME commit --allow-empty -m "Initial commits"

    echo "looping again..."
    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        echo rm -rf -- $HOME/$filename
        rm -rf -- $HOME/$filename
        echo ln -s "$DOTFILES_HOME/LINK_TO_HOME/$filename" "$HOME/$filename"
        ln -s "$DOTFILES_HOME/LINK_TO_HOME/$filename" "$HOME/$filename"

        echo git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME add --force "$HOME/$filename"
        git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME add --force "$HOME/$filename"

    done
    echo "done2"
    git --git-dir=$SEPARATE_GIT_DIR --work-tree=$HOME commit -m "Second commit"

}

loop "$DOTFILES_HOME/LINK_TO_HOME"
echo "final done"
