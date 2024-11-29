#!/bin/bash

# This is my test dotfiles installer.
# Use cURL to invoke the script. ie:
#
# curl https://raw.githubusercontent.com/davlug3/dotfiles/new/setupgit.sh | GIT_BIN=/usr/local/bin/git DDOTFILES_HOME=$HOME/.config bash

DDOTFILES_GIT_BIN=${DDOTFILES_GIT_BIN:-/usr/bin/git}
DDOTFILES_GIT_REPO_URL=${DDOTFILES_GIT_REPO_URL:-https://github.com/davlug3/dotfiles}
DDOTFILES_HOME=${DDOTFILES_HOME:-$HOME/.ddconfig}
DDOTFILES_GIT_NAME=${DDOTFILES_GIT_NAME:-Dave}
DDOTFILES_GIT_EMAIL=${DDOTFILES_GIT_EMAIL:-Dave@Dave}
DDOTFILES_HOME=${DDOTFILES_HOME:-$HOME/.ddconfig}
DDOTFILES_SEPARATE_GIT_IGNORE=${DDOTFILES_SEPARATE_GIT_IGNORE:-$HOME/.ddgitignore}


if [[ -e $HOME/.git ]]; then
    echo "Git is already initialized at the \$HOME directory. Trying to rename to \$HOME/.git.backup..."
    mv $HOME/.git $HOME/.git.backup

    if [[ $? -eq 0 ]]; then
        echo "Success!"
        echo "The old \$HOME/.git directory is now \$HOME/.git.backup. It will be restored when you run the uninstall script that comes with this config."
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
$DDOTFILES_GIT_BIN config core.excludesFile $DDOTFILES_SEPARATE_GIT_IGNORE

if [[ -f "$DDOTFILES_SEPARATE_GIT_IGNORE" ]]; then
    echo "File $DDOTFILES_SEPARATE_GIT_IGNORE exists."
    echo "Deleting..."
    rm -rf -- "$DDOTFILES_SEPARATE_GIT_IGNORE"
fi

echo "creating gitignore"
touch $DDOTFILES_SEPARATE_GIT_IGNORE
echo * >> $DDOTFILES_SEPARATE_GIT_IGNORE

if [[ ! "$(cat "$DDOTFILES_SEPARATE_GIT_IGNORE")" == "*" ]]; then
    echo "Invalid file $DDOTFILES_SEPARATE_GIT_IGNORE. Please handle accordingly."
    exit 1
fi

echo "git add"
$DDOTFILES_GIT_BIN add --force .

echo "Add safe directory"
$DDOTFILES_GIT_BIN config --add safe.direcotry $DDOTFILES_GIT_REPO_URL/.git
$DDOTFILES_GIT_BIN config --add safe.direcotry $DDOTFILES_GIT_REPO_URL
$DDOTFILES_GIT_BIN config user.email $DOTFILES_GIT_EMAIL
$DDOTFILES_GIT_BIN config user.name $DOTFILES_GIT_NAME

echo "Fetching the repo..."
$DDOTFILES_GIT_BIN -c safe.directory=$DDOTFILES_GIT_REPO_URL/.git clone --branch new "$DDOTFILES_GIT_REPO_URL" "$DDOTFILES_HOME" && echo "Fetching done." || { echo "git clone failed. Exiting..."; exit 1; }

touch $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_BIN="${DDOTFILES_GIT_BIN}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_REPO_URL="${DDOTFILES_GIT_REPO_URL}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_HOME="${DDOTFILES_HOME}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_NAME="${DDOTFILES_GIT_NAME}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_GIT_EMAIL="${DDOTFILES_GIT_EMAIL}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_HOME="${DDOTFILES_HOME}" >> $DDOTFILES_HOME/.env
echo export DDOTFILES_SEPARATE_GIT_IGNORE="${DDOTFILES_SEPARATE_GIT_IGNORE}" >> $DDOTFILES_HOME/.env

loop() {
    echo "Linking files..."

    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        if [[ -e "$HOME/$filename" ]]; then
            echo "   Found file $HOME/$filename. Backing up..."
            $DDOTFILES_GIT_BIN add --force "$HOME/$filename"
        fi
    done
    echo "loop 1 done. committing..."

    $DDOTFILES_GIT_BIN commit --author="$DDOTFILES_GIT_NAME $DDOTFILES_GIT_EMAIL" --allow-empty -m "Initial commits"

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

        $DDOTFILES_GIT_BIN add --force "$HOME/$filename"
    done
    echo "loop 2 done."
    $DDOTFILES_GIT_BIN commit --author="$DDOTFILES_GIT_NAME $DDOTFILES_GIT_EMAIL" -m "Second commit"

}

loop "$DDOTFILES_HOME/LINK_TO_HOME"
echo "Done!"
