#!/bin/bash

#parse some arguments
ask=1
for arg in "$@"; do
    if [ "$arg" == "-y" ] || [ "$arg" == "--yes" ]; then
        ask=0
        break
    fi
done


if (( ask != 0 )); then 
	echo "Do you want to continue? (y/n): " 
	read response </dev/tty
	if [[ "${response,,}" != "y" ]]; then
            echo "Exiting..."
	    exit 1
	fi
fi


#currently assuming dotfiles are hosted on github
if [ -z "$DOTFILES_URL" ]; then
    export DOTFILES_URL=https://github.com/davlug3/dotfiles
fi
REPO_NAME="${DOTFILES_URL#*github.com/}"

#
# Check if install_git.sh exists, download if missing
 if [ ! -f "~/.dotfiles/install_git.sh" ]; then
     echo "install_git.sh not found. Downloading..."
     cd $HOME
     curl -O http://cdn.jsdelivr.net/gh/$REPO_NAME/.dotfiles@git/install_git.sh
     if [ $? -ne 0 ]; then
             echo "Failed to download install_git.sh."
             exit 1
     fi
    ~/install_git.sh || { echo "install_git.sh failed"; exit 1; }
    rm $HOME/install_git.sh

else
echo "installing git..."
    ~/.dotfiles/install_git.sh
fi



echo "installing dotfiles..."
./install_dotfiles.sh || { echo "install_dotfiles.sh failed"; exit 1; }
./install_tmux.sh || { echo "install_tmux.sh failed"; exit 1; }
./install_tpm.sh || { echo "install_tpm.sh failed"; exit 1; }



# Check the final status
if [ $? -eq 0 ]; then
    echo "All scripts completed successfully."
else
    echo "One of the scripts failed."
    exit 1
fi

