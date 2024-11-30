#!/bin/bash

# This is my test dotfiles installer.
# Use cURL to invoke the script. ie:
#
# curl https://raw.githubusercontent.com/davlug3/dotfiles/new/setupgit.sh | DDOTFILES_GIT_BIN=/usr/local/bin/git DDOTFILES_HOME=$HOME/.ddconfig bash

DDOTFILES_GIT_BIN=${DDOTFILES_GIT_BIN:-/usr/bin/git}
DDOTFILES_GIT_REPO_URL=${DDOTFILES_GIT_REPO_URL:-https://github.com/davlug3/dotfiles}
DDOTFILES_HOME=${DDOTFILES_HOME:-$HOME/.ddconfig}
DDOTFILES_GIT_NAME=${DDOTFILES_GIT_NAME:-Dave}
DDOTFILES_GIT_EMAIL=${DDOTFILES_GIT_EMAIL:-Dave@Dave}
DDOTFILES_HOME=${DDOTFILES_HOME:-$HOME/.ddconfig}

# This is still not operational
DDOTFILES_SEPARATE_GITIGNORE=${DDOTFILES_SEPARATE_GITIGNORE:-$HOME/.gitignore}


if [[ -e $HOME/.git ]]; then
    echo "Git is already initialized at the \$HOME directory. Trying to rename to \$HOME/.git.backup..."
    mv $HOME/.git $HOME/.git.backup

    if [[ $? -eq 0 ]]; then
        echo "Success!"
        echo "The old \$HOME/.git directory is now \$HOME/.git.backup. It will be restored when you run the uninstall script that comes with this config."
        echo "If this script fails, just rename this with:"
        echo "   mv $HOME/.git.backup $HOME/.git"
    else
        echo "Move operation failed. You have to manually move the \$HOME/.git directory (or rename it) somewhere else."
        echo "Exiting..."
        exit 1
    fi
fi



cd $HOME
$DDOTFILES_GIT_BIN init --initial-branch=main $HOME > /dev/null
if [ ! -d ".git" ]; then
    echo "Error initializing \$HOME as a git directory. "
    echo "If you continue, you will lose the ability to restore your \$HOME directory back to"
    echo "its original state. Do you want to continue? (Y/n)"
    read -r user_input

    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        echo "Continuing..."
    else
        echo "Aborting."
        exit 1
    fi
else
    echo "Git repository at \$HOME successfully initialized."
fi

echo "config..."
$DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME config core.excludesFile $DDOTFILES_SEPARATE_GITIGNORE

if [[ -f "$DDOTFILES_SEPARATE_GITIGNORE" ]]; then
    echo "File $DDOTFILES_SEPARATE_GITIGNORE exists."
    echo "Deleting..."
    rm -rf -- "$DDOTFILES_SEPARATE_GITIGNORE"
fi

echo "creating gitignore"
touch $DDOTFILES_SEPARATE_GITIGNORE
echo * >> $DDOTFILES_SEPARATE_GITIGNORE

if [[ ! "$(cat "$DDOTFILES_SEPARATE_GITIGNORE")" == "*" ]]; then
    echo "Invalid file $DDOTFILES_SEPARATE_GITIGNORE. Please handle accordingly."
    exit 1
fi

echo "git add"
$DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME add --force .

echo "Add safe directory"
$DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME config --add safe.direcotry $DDOTFILES_GIT_REPO_URL/.git
$DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME config --add safe.direcotry $DDOTFILES_GIT_REPO_URL
$DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME config user.email $DDOTFILES_GIT_EMAIL
$DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME config user.name $DDOTFILES_GIT_NAME

echo "Fetching the repo..."
$DDOTFILES_GIT_BIN -c safe.directory=$DDOTFILES_GIT_REPO_URL/.git clone --branch new "$DDOTFILES_GIT_REPO_URL" "$DDOTFILES_HOME" && echo "Fetching done." || { echo "git clone failed. Exiting..."; exit 1; }

touch $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_BIN="${DDOTFILES_GIT_BIN}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_REPO_URL="${DDOTFILES_GIT_REPO_URL}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_HOME="${DDOTFILES_HOME}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_NAME="${DDOTFILES_GIT_NAME}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_EMAIL="${DDOTFILES_GIT_EMAIL}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_HOME="${DDOTFILES_HOME}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_SEPARATE_GITIGNORE="${DDOTFILES_SEPARATE_GITIGNORE}" >> $DDOTFILES_HOME/.env

loop() {
    echo "Linking files..."

    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        if [[ -e "$HOME/$filename" ]]; then
            echo "   Found file $HOME/$filename. Backing up..."
            $DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME add --force "$HOME/$filename"
        fi
    done
    echo "loop 1 done. committing..."

    $DDOTFILES_GIT_BIN \
        --git-dir=$HOME/.git \
        --work-tree=$HOME \
        commit \
        --allow-empty -m "Initial commits"

    echo "looping again..."
    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        if [[ -e "$HOME/$filename" ]]; then
            echo "   Found file $HOME/$filename. Removing..."
            rm -rf -- $HOME/$filename
        fi

        echo "   linking $HOME/$filename..."
        ln -s "$DDOTFILES_HOME/LINK_TO_HOME/$filename" "$HOME/$filename"

        $DDOTFILES_GIT_BIN --git-dir=$HOME/.git --work-tree=$HOME add --force "$HOME/$filename"
    done

    echo "loop 2 done. committing..."
    $DDOTFILES_GIT_BIN \
        --git-dir=$HOME/.git \
        --work-tree=$HOME \
        commit \
        -m "Second commit"

}

loop "$DDOTFILES_HOME/LINK_TO_HOME"
echo "Done!"
