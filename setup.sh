#!/bin/bash

GIT_BIN=/usr/bin/git
BACKUP_DIR=$HOME/.config_backup
DOTFILES_HOME=$HOME/.config_dotfiles
# DOTFILES_REPO_URL="/dotfiles"

# CONFIG="$GIT_BIN --git-dir=$HOME/$GIT_REPO --work-tree=$HOME"


# $GIT_BIN init --bare $HOME/.cfg

# echo * >> "$HOME/.gitignore"

# $GIT_BIN add -f .gitignore



# curl 

# config() {
# 	$CONFIG "$@"
# }

# config config --local status.showUntrackedFiles no
# config config user.email "dave@dave"
# config config user.name "Dave"

# config branch -M backup
# config add "$HOME/.gitignore"
# config commit -m "initial backup commit"


# config checkout -b main
# config remote add origin $DOTFILES_REPO_URL


backup_and_link() {
	# if ($BACKUP_DIR not exists ) mkdir $BACKUP_DIR
	# if ($HOME/$@ exists) 
	# 	mv $HOME/$@ $BACKUP_DIR
	# link $@ $HOME


	# if backup dir doesnt exist, create it
	if [ ! -d "$BACKUP_DIR"]; then 
		mkdir -p "$BACKUP_DIR"
	fi

	# check if file in $1 exist, if yes, move it
	if [ -e "$HOME/$1" ]; then
		mv "$HOME/$1" "$BACKUP_DIR"
	fi

	ln -s "$PWD/$1" "$HOME/$1"
	echo "$PDS/$1 >> $HOME/$1" >> $DOTFILES_HOME/tracker.txt
}



for item in "$DOTFILES_HOME"/*; do
	filename=$(basename "$item") 
	backup_and_link "$filename"
done


