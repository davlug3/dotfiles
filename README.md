# My Dotfiles repo

*this is primarily used for vim, but i may use this for other things as well*

Instructions

```
    # clone the repo
    cd ~
    git clone https://github.com/davlug3/dotfiles .dotfiles



    # create the symlinks using stow
    ~/.dotfiles/install.sh


    # to make ctags work, build universal-ctags from source
    ~/.dotfiles/install_universal_ctags.sh

    # install plugins using vim-plug 
    vim
    :PlugInstall

    # Done!
```


---

This repo is meant for my personal use only.
I am still learning, a lot of the configurations here are copied from various sources on the internet.


for now, to view all symlinks in home directory, just 

    ```
        find ~ -maxdepth 1 -type l -ls
    ```

