#!/bin/bash

GIT_BIN=/usr/bin/git
DOTFILES_GIT_URL=/dotfiles_setup/dotfiles
BACKUP_DIR=$HOME/.config_backup
DOTFILES_HOME=$HOME/.config_dotfiles

echo $GIT_BIN
echo $DOTFILES_GIT_URL
echo $BACKUP_DIR
echo $DOTFILES_HOME

exit 1
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

recurse() {
	
	for item in "$1"/LINK_TO_HOME/{*,.*}; do
		echo "item $item ...."
		if [[ "$item" == "$1/." || "$item" == "$dir/.." ]]; then
			continue
		fi

		if [[ -d "$item" ]]; then
			recurse "$item"
		elif [[ -f "$item" ]]; then 
			filename=$(basename "$item") 
			echo "$now backup that"
			# backup_and_link "$filename"
		fi
	done
}
recurse "$DOTFILES_HOME"


