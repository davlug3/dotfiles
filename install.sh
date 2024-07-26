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


#package="$SCRIPT_DIR/vim/pack"
#
# Add submodules here in this format
#cd ~ || exit

# plugins in plugins/start
#git clone https://github.com/scrooloose/nerdtree $package/plugins/start/nerdtree
#git clone https://github.com/Xuyuanp/nerdtree-git-plugin $package/plugins/start/nerdtree-git-plugin
#
## colors in colors/start
#git clone https://github.com/rakr/vim-one.git $package/colors/start/one
#
## vue test
#git clone https://github.com/posva/vim-vue.git $package/plugins/start/vim-vue
#
#
# vim ~/.vimrc
# git submodule update --remote --merge
# git commit
#
echo "Done!"
