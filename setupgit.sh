#!/bin/bash

# This is my test dotfiles installer.
# Use cURL to invoke the script. ie:
#
# curl https://raw.githubusercontent.com/davlug3/dotfiles/new/setupgit.sh | GIT_BIN=/usr/local/bin/git DOTFILES_HOME=$HOME/.config bash

GIT_BIN=${GIT_BIN:-/usr/bin/git}
DOTFILES_GIT_REPO_URL=${DOTFILES_GIT_REPO_URL:-https://github.com/davlug3/dotfiles}
DOTFILES_HOME=${DOTFILES_HOME:-$HOME/.ddconfig}
SEPARATE_GIT_IGNORE=${SEPARATE_GIT_IGNORE:-$HOME/.ddgitignore}

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
$GIT_BIN init --Initial-branch=main $HOME > /dev/null
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

$GIT_BIN config core.excludesFile $SEPARATE_GIT_IGNORE

if [[ -f "$SEPARATE_GIT_IGNORE" ]]; then
    echo "File $SEPARATE_GIT_IGNORE exists. Please handle it accordingly."
    echo "Exiting."
    exit 1
fi

touch $SEPARATE_GIT_IGNORE
echo * >> $SEPARATE_GIT_IGNORE

if [[ ! "$(cat "$SEPARATE_GIT_IGNORE")" == "*" ]]; then
    echo "Invalid file $SEPARATE_GIT_IGNORE. Please handle accordingly."
    exit 1
fi

$GIT_BIN add --force .

echo "Fetching the repo..."
$GIT_BIN clone --branch new "$DOTFILES_GIT_REPO_URL" "$DOTFILES_HOME" && echo "Fetching done." || { echo "git clone failed. Exiting..."; exit 1; }


loop() {
    echo "Linking files..."

    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        if [[ -e "$HOME/$filename" ]]; then
            echo "   Found file $HOME/$filename. Backing up..."
            $GIT_BIN add --force "$HOME/$filename"
        fi
    done
    echo "loop 1 done. committing..."

    $GIT_BIN commit --allow-empty -m "Initial commits"

    echo "looping again..."
    for item in "$1"/{*,.*}; do
        if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
            continue
        fi

        filename=$(basename "$item")
        echo "   removing $HOME/$filename..."
        rm -rf -- $HOME/$filename

        echo "   linking $HOME/$filename..."
        ln -s "$DOTFILES_HOME/LINK_TO_HOME/$filename" "$HOME/$filename"

        $GIT_BIN add --force "$HOME/$filename"
    done
    echo "loop 2 done."
    $GIT_BIN commit -m "Second commit"

}

loop "$DOTFILES_HOME/LINK_TO_HOME"
echo "Done!"
