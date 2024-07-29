#!/bin/bash


#get script dir
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# check for stow
if ! command -v stow &> /dev/null
then
	echo "Stow not found. Check first if it is installed"
	exit 1
fi

cd $SCRIPT_DIR || exit

#stow individual directories
stow -t ~ vim


echo "Done!"
