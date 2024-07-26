#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "Script directory $SCRIPT_DIR"

cd $SCRIPT_DIR || exit

git submodule add \
  https://github.com/scrooloose/nerdtree \
  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/nerdtree"

git submodule add \
  https://github.com/Xuyuanp/nerdtree-git-plugin \
  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/nerdtree-git-plugin"


git submodule add \
  https://github.com/tpope/vim-commentary.git \
  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/vim-commentary"


git submodule add \
  https://github.com/majutsushi/tagbar.git \
  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/tagbar"

git submodule add \
  https://github.com/junegunn/fzf.git \
  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/fzf"


git submodule add \
  https://github.com/junegunn/fzf.vim.git \
  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/fzf.vim"

git submodule add \
    https://github.com/preservim/vimux.git \
  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/vimux"


# git submodule add \
#  https://github.com/jakedouglas/exuberant-ctags.git \
#  "$SCRIPT_DIR/vim/.vim/pack/plugins/start/exuberant-ctags"


# git submodule add \
#    https://github.com/ycm-core/YouCompleteMe.git \
#   "$SCRIPT_DIR/vim/.vim/pack/plugins/start/YouCompleteMe"
#

git rm $SCRIPOT_DIR/vim/.vim/pack/plugins/start/YouCompleteMe

