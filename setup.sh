#!/bin/bash


echo "Welcome!"
GIT_BIN=/usr/bin/git
DOTFILES_GIT_URL=https://github.com/davlug3/dotfiles
BACKUP_DIR=$HOME/.ddbackup
DOTFILES_HOME=$HOME/.ddhome




# this moves or copies files to $BACKUP_DIR,
# making sure that $BACKUP_DIR exists before
# doing so
mvcpp() {
	# if backup dir doesnt exist, create it
	if [ ! -d "$BACKUP_DIR" ]; then
		mkdir -p "$BACKUP_DIR"
	fi

	if [ "$1" = "move" ]; then
		mv "$2" "$BACKUP_DIR"
		echo "$2 has been moved to $BACKUP_DIR"
	elif [ "$1" = "copy" ]; then
		cp -r "$2" "$BACKUP_DIR"
		echo "$2 has been copied to $BACKUP_DIR"
	else
		echo "Invalid action. Use mvcpp 'move | copy' <path>"
	fi
}

backup_and_link() {
	# check if file in $1 exist, if yes, move it
	if [ -e "$HOME/$1" ]; then
		mvcpp move "$HOME/$1"
		moved=true
	fi
	ln -s "$DOTFILES_HOME/LINK_TO_HOME/$1" "$HOME/$1"

	if [ "$moved" = true ]; then
	 	# moved,fromAddr,toAddr,linkAddr
		echo "moved,$HOME/$1,$BACKUP_DIR/$1,$DOTFILES_HOME/LINK_TO_HOME/$1" >> $DOTFILES_HOME/tracker.txt
	else
	 	# linked,fromAddr,toAddr,linkAddr
		echo "linked,$DOTFILES_HOME/LINK_TO_HOME/$1,$HOME/$1,$DOTFILES_HOME/LINK_TO_HOME/$1" >> $DOTFILES_HOME/tracker.txt
	fi

	echo "successfully linked $DOTFILES_HOME/LINK_TO_HOME/$1 to $HOME/$1"
}


$GIT_BIN clone "$DOTFILES_GIT_URL" "$DOTFILES_HOME"  && echo "git clone succeeded." || { echo "git clone failed. Exiting..."; exit 1; }
touch $DOTFILES_HOME/.env
echo export DDOTFILES_GIT_BIN=$GIT_BIN >> $DOTFILES_HOME/.env
echo export DDOTFILES_DOTFILES_GIT_URL=$DOTFILES_GIT_URL >> $DOTFILES_HOME/.env
echo export DDOTFILES_BACKUP_DIR=$BACKUP_DIR >> $DOTFILES_HOME/.env
echo export DDOTFILES_DOTFILES_HOME=$DOTFILES_HOME >> $DOTFILES_HOME/.env

source $DOTFILES_HOME/.env



process_bashrc() {
	[ -f "$HOME/.bashrc" ] && mvcpp copy "$HOME/.bashrc"
	echo "###ddconfig###" >> $HOME/.bashrc
	echo "[ -f \"$DOTFILES_HOME/.env\" ] && source $DOTFILES_HOME/.env" >> $HOME/.bashrc
	echo "[ -f \"$DOTFILES_HOME/SHELL/.bashrc\" ] && source $DOTFILES_HOME/SHELL/.bashrc" >> $HOME/.bashrc
	echo "###ddconfigend###" >> $HOME/.bashrc
	echo "bashrc" >> $DOTFILES_HOME/tracker.txt
}

loop() {
	for item in "$1"/{*,.*}; do
		if [[ "$item" == "$1/*" || "$item" == "$1/." || "$item" == "$dir/.." ]]; then
			continue
		fi



		filename=$(basename "$item")
		# echo "$filename backup that"
		backup_and_link $filename
	done
}

loop "$DOTFILES_HOME/LINK_TO_HOME"
process_bashrc
source $HOME/.bashrc

