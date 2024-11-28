#!/bin/bash
# File to be parsed

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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


sanitize_input() {
    local input="$1"
    # Allow only alphanumeric characters, dashes, underscores, slashes, and dots
    if [[ "$input" =~ ^[a-zA-Z0-9/_\.-]+$ ]]; then
        echo "$input"
    else
        echo "Invalid input: $input"
        exit 1
    fi
}


saferm() {
        local target_dir=$(sanitize_input "$1")
        local safe_path="$HOME"

        if [[ "$target_dir" != "$safe_path"* ]]; then
            echo "Operation restricted to directories within $safe_path."
            exit 1
        fi

        rm -rf -- "$target_dir"
        echo "Successfully deleted $target_dir"
}


# Loop through each line in the file
echo Restoring files on $file...
while IFS= read -r line; do
    # Split the line by the delimiter ">>"
    line=$(echo "$line" | xargs)
    IFS=',' read -r -a parts <<< "$line"

    action=${parts[0]}


    if [ action = 'moved_linked' ]; then
        if [ ${#parts[@]} -ge 4 ]; then
            copyto=${parts[1]}
            copyfrom=${parts[2]}

            echo "removing $copyto..."
            saferm $copyto
            echo transferring $copyfrom to $copyto...
            cp -f $copyfrom $copyto
            echo done.
        else
            echo "ERROR! INCOMPLETE PARTS"
            exit 1
        fi
    fi



    if [ action = 'linked' ]; then
        if [ ${#parts[@]} -ge 3 ]; then
            addr=${parts[2]}
            echo "removing $addr..."
            saferm $addr
            echo done.
        else
            echo "ERROR! INCOMPLETE PARTS"
            exit 1
        fi
    fi


done < "$file"
echo "done restoring files."

echo "removing .ddconfig"
saferm $DDOTFILES_DOTFILES_HOME
echo "removing .ddconfig_backup"
saferm $DDOTFILES_BACKUP_DIR
echo "removing ddconfigishere"
rm -rf ~/ddconfigishere
