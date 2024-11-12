#!/bin/bash

GIT_BIN=/usr/bin/git
DOTFILES_GIT_URL=/dotfiles_setup/dotfiles
BACKUP_DIR=$HOME/.config_backup
DOTFILES_HOME=$HOME/.config_dotfiles



backup_and_link() {
	# check if file in $1 exist, if yes, move it
	if [ -e "$HOME/$1" ]; then
		# if backup dir doesnt exist, create it
		if [ ! -d "$BACKUP_DIR" ]; then 
			mkdir -p "$BACKUP_DIR"
		fi
		mv "$HOME/$1" "$BACKUP_DIR"
	fi

	ln -s "$PWD/$1" "$HOME/$1"
	echo "link $PDS/$1 >> $HOME/$1" >> $DOTFILES_HOME/tracker.txt
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
	[ -f $HOME/.bashrc ] && cp $HOME/.bashrc $BACKUP_DIR
	echo "###ddconfig###" >> $HOME/.bashrc
	echo "source $DOTFILES_HOME/.env" >> $HOME/.bashrc
	echo "source $DOTFILES_HOME/SHELL/.bashrc" >> $HOME/.bashrc
	echo "###ddconfigend###" >> $HOME/.bashrc
}

recurse() {
	for item in "$1"/{*,.*}; do
		if [[ "$item" == "$1/." || "$item" == "$dir/.." ]]; then
			continue
		fi

		# echo "item $item ....."
		# if [[ -d "$item" ]]; then
		# 	recurse "$item"
		# elif [[ -f "$item" ]]; then 
			filename=$(basename "$item") 
			echo "$now backup that"
			backup_and_link "$filename"
		# fi
	done
}
recurse "$DOTFILES_HOME/LINK_TO_HOME"
process_bashrc
source $HOME/.bashrc

