#!/bin/bash

GIT_BIN=/usr/bin/git
DOTFILES_GIT_URL=/dotfiles_setup/dotfiles
BACKUP_DIR=$HOME/.config_backup
DOTFILES_HOME=$HOME/.config_dotfiles

mvcpp() {
	# if backup dir doesnt exist, create it
	if [ ! -d "$BACKUP_DIR" ]; then
		mkdir -p "$BACKUP_DIR"
	fi

	if [ "$1" = "move" ]; then
		mv "$HOME/$2" "$BACKUP_DIR"
		echo "$HOME/$2 has been moved to $BACKUP_DIR" 
	elif [ "$1" = "copy" ]; then
		cp -r "$HOME/$2" "$BACKUP_DIR"
		echo "$HOME/$2 has been copied to $BACKUP_DIR" 
	else
		echo "Invalid action. Use mvcpp 'move | copy' <path>"
	fi
}

backup_and_link() {
	# check if file in $1 exist, if yes, move it
	if [ -e "$HOME/$1" ]; then
		mvcpp move $1
	fi

	ln -s "$DOTFILES_HOME/LINK_TO_HOME/$1" "$PWD/$1" 
	echo "link >> $DOTFILES_HOME/LINK_TO_HOME/$1 >> $PWD/$1" >> $DOTFILES_HOME/tracker.txt
	echo Successfully linked $PCS/$1 to  $HOME/$1
}


$GIT_BIN clone "$DOTFILES_GIT_URL" "$DOTFILES_HOME"
touch $DOTFILES_HOME/.env
echo DDOTFILES_GIT_BIN=$GIT_BIN >> $DOTFILES_HOME/.env
echo DDOTFILES_DOTFILES_GIT_URL=$DOTFILES_GIT_URL >> $DOTFILES_HOME/.env
echo DDOTFILES_BACKUP_DIR=$BACKUP_DIR >> $DOTFILES_HOME/.env
echo DDOTFILES_DOTFILES_HOME=$DOTFILES_HOME >> $DOTFILES_HOME/.env

source $DOTFILES_HOME/.env 



process_bashrc() {
	mvcpp copy "$HOME/.bashrc" "$BACKUP_DIR/.bashrc"
	echo "###ddconfig###" >> $HOME/.bashrc
	echo "[ -f \"$DOTFILES_HOME/.env\" ] && source $DOTFILES_HOME/.env" >> $HOME/.bashrc
	echo "[ -f \"$DOTFILES_HOME/SHELL/.bashrc\" ] && source $DOTFILES_HOME/SHELL/.bashrc" >> $HOME/.bashrc
	echo "###ddconfigend###" >> $HOME/.bashrc
}

recurse() {
	for item in "$1"/{*,.*}; do
		if [[ "$item" == "$1/." || "$item" == "$dir/.." ]]; then
			continue
		fi

		filename=$(basename "$item") 
		echo "$now backup that"
		backup_and_link "$filename"
	done
}

recurse "$DOTFILES_HOME/LINK_TO_HOME"
process_bashrc
source $HOME/.bashrc

