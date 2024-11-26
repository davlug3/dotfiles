#!/bin/bash
# File to be parsed

script_dir="$(cd "$(dirname "$(BASH_SOURCE[0])")" && pwd)"
source "$HOME/.bashrc"
source $script_dir/.env

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

    action=${parts[0]}


    if [ action = 'moved_linked' ]; then
        if [ ${#parts[@]} -ge 4 ]; then
            copyto=${parts[1]}
            copyfrom=${parts[2]}
            cp -f $copyfrom $copyto
        else
            echo "ERROR! INCOMPLETE PARTS"
            exit 1
        fi
    fi



    if [ action = 'linked' ]; then
        if [ ${#parts[@]} -ge 3 ]; then
            addr=${parts[2]}
            rm -rf $addr
        else
            echo "ERROR! INCOMPLETE PARTS"
            exit 1
        fi
    fi

    # Check if parts has enough elements
    if [ ${#parts[@]} -ge 2 ]; then
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


echo "removing .ddconfig"
rm -rf ~/.ddconfig
echo "removing .ddconfig_backup"
rm -rf ~/.ddconfig_backup
echo "removing ddconfigishere"
rm -rf ~/ddconfigishere
