#!/bin/bash
# File to be parsed
source "$HOME/.bashrc"
source .env

echo MY_HOME = $DDOTFILES_DOTFILES_HOME



#check if .env is sourced
if [ -z "${DDOTFILES_DOTFILES_HOME}" ]; then 
	echo "Environment variable \$DDOTFILES_DOTFILES_HOME not set.."
	echo 'Did you run source ~/.bashrc?'
	exit 1
fi

file=$DDOTFILES_DOTFILES_HOME/tracker.txt


# Loop through each line in the file
while IFS= read -r line; do
    # Split the line by the delimiter ">>"
    IFS='>>' read -r -a parts <<< "$line"

    copyfrom=${parts[3]}
    copyto=${parts[2]}
	echo copyfrom=$copyfrom
	echo copyto=$copyto
continue
    url=${parts[0]}
    url=$(echo "$url" | sed -e 's/^[[:space:]]*//')
    url="${url#$DDOTFILES_DOTFILES_HOME/LINK_TO_HOME/}"
    wholeurl="$DDOTFILES_BACKUP_DIR/$url"
    echo "my url=$wholeurl"

   # rm -rf ${parts[2]}
    

done < "$file"
