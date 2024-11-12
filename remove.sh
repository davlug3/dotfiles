#!/bin/bash
# File to be parsed

file=$HOME/

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
