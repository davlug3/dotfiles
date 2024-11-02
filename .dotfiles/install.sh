#!/bin/bash

ask=false

for arg in "$@"; do
    if [ "$arg" == "--ask" ]; then
        ask=true
        break
    fi
done

#
#  # If '--ask' was provided, prompt the user
#  if [ "$ask" = true ]; then
#      read -p "Do you want to continue? (y/n): " response
#      if [[ "$response" != "y" && "$response" != "Y" ]]; then
#          echo "Exiting."
#          exit 1
#      fi
#  fi



read -p "Do you want to continue? (y/n): " response
if [[ "${response,,}" != "y" ]]; then
        echo "Exiting."
            exit 1
fi


if [ -z "$DOTFILES_URL" ]; then
    export DOTFILES_URL=https://github.com/davlug3/dotfiles
fi


REPO_NAME="${DOTFILES_URL#*github.com/}"

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

