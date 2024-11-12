#!/bin/bash
# File to be parsed

if [ -z "${DDOTFILES_DOTFILES_HOME}" ]; then 
	echo "Environment variable \$DDOTFILES_DOTFILES_HOME not set."
	echo 'Did you run \`source ~/.bashrc`\?'
	exit 1
fi

file=$DDOTFILES_DOTFILES_HOME/tracker.txt


# Loop through each line in the file
while IFS= read -r line; do
    # Split the line by the delimiter ">>"
    IFS='>>' read -r -a parts <<< "$line"
    
    # Access the split parts (e.g., parts[0], parts[1], etc.)
    echo "Part 1: ${parts[0]}"
    echo "Part 2: ${parts[1]}"
    
    # If there are more parts, print them too
    for i in "${!parts[@]}"; do
        echo "Part $((i + 1)): ${parts[i]}"
    done

    echo "----"
done < "$file"
