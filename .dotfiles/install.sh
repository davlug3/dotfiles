#!/bin/bash

ask=false

for arg in "$@"; do
    if [ "$arg" == "--ask" ]; then
        ask=true
        break
    fi
done

# If '--ask' was provided, prompt the user
if [ "$ask" = true ]; then
    read -p "Do you want to continue? (y/n): " response
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo "Exiting."
        exit 1
    fi
fi



./install_git.sh && \
	./install_dotfiles.sh \
    ./install_tmux.sh \
    ./install_tpm.sh




# Check the final status
if [ $? -eq 0 ]; then
    echo "All scripts completed successfully."
else
    echo "One of the scripts failed."
    exit 1
fi

