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
        copyfrom=${parts[1]}
        copyto=${parts[2]}

        if [ "$action" = "moved_linked" ]; then
            echo "Performing moved_linked: Removing $copyfrom and copying $copyto to $copyfrom"
            rm -rf $copyfrom
            if [ $? -eq 0 ]; then
                    echo "Successfully removed $copyfrom"
            else
                echo "Error: failed to remove $copypfrom"
            fi

            cp "$copyto" "$copyfrom"
            if [ $? -eq 0 ]; then
                echo "Successfully copied $copyto to $copyfrom"
            else
                echo "Error: Failed to copy $copyto to $copyfrom"
            fi
        fi

        if [ "$action" = "linked" ]; then
            rm -rf $copyto
            if [ $? -eq 0 ]; then
                echo "Successfully removed $copyto"
            else 
                echo "Error: Failed to remove $copyto"
            fi
        fi

        if [ "$action" = "bashrc" ]; then
            sed -i '/###ddconfig###/,/###ddconfigend###/d' ~/.bashrc
            if [ $? -eq 0 ]; then
                echo "Successfully removed the tag in .bashrc"
            else 
                echo "Error: Failed to remove the tag in .bashrc"
            fi
        fi

    else
        echo "Error: Not enough parts in line"
    fi


done < "$file"
