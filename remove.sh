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
    line=$(echo "$line" | xargs)
    IFS=',' read -r -a parts <<< "$line"

    # Check if parts has enough elements
    if [ ${#parts[@]} -ge 4 ]; then
        action=${parts[0]}
        copyto=${parts[1]}
        copyfrom=${parts[2]}

        if [ "$action" = "moved_linked" ]; then
            rm -rf $copyto
            cp $copyfrom $copyto
        fi

        if [ "$action" = "linked" ]; then
            rm -rf $copyto
        fi

        

    else
        echo "Error: Not enough parts in line"
    fi


done < "$file"
