#!/bin/bash

GIT_BIN=/usr/bin/git
DOTFILES_GIT_URL=/dotfiles_setup/dotfiles
BACKUP_DIR=$HOME/.config_backup
DOTFILES_HOME=$HOME/.config_dotfiles
backup_and_link() {

	# if backup dir doesnt exist, create it
	if [ ! -d "$BACKUP_DIR" ]; then 
		mkdir -p "$BACKUP_DIR"
	fi

	# check if file in $1 exist, if yes, move it
	if [ -e "$HOME/$1" ]; then
		mv "$HOME/$1" "$BACKUP_DIR"
	fi

	ln -s "$PWD/$1" "$HOME/$1"
	echo "$PDS/$1 >> $HOME/$1" >> $DOTFILES_HOME/tracker.txt
}

$GIT_BIN clone "$DOTFILES_GIT_URL" "$DOTFILES_HOME"

for item in "$DOTFILES_HOME"/*; do
	filename=$(basename "$item") 
	backup_and_link "$filename"
done


