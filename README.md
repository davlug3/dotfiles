# davlug3 dotfiles

## Requirements

- `curl`
- `git`
- nodejs (Install script via nvm provided in `INSTALLER/nodejs.sh`)

***This assumes bash to be your preferred shell***

## Instructions

### To install

1. install the dependencies (if not available)
2. run `setup.sh`:

- `curl https://raw.githubusercontent.com/davlug3/dotfiles/master/setup.sh | bash`

### To uninstall

- run `remove.sh`

### Development

For debugging this repo:

1. Clone this repo  
   - `git clone https://github.com/davlug3/dotfiles $HOME/dd`

2. Pipe `setup.sh` to bash, then set `DDOTFILES_GIT_REPO_URL` environment
variable to your clone directory.  
   - `cat $HOME/dd/setup.sh | DDOTFILES_GIT_REPO_URL=$HOME/dd/setup.sh bash`

## About

This repository is designed to quickly configure my preferred setup on
any (ideally) Unix-like system while keeping the system modifications minimal.

I am actively testing this setup on WSL (Windows Subsystem for Linux).
Initially created for managing my Vim configuration, this repository has
evolved to include all my custom configurations for Unix environments.

## Key Features

- **Version Control for $HOME**:
  - The `setup.sh` script initializes your `$HOME` directory as a Git
  repository.
  - The initial state of your `$HOME` directory is committed as the repository's
  first commit. This allows you to:
    - Track and manage changes to configuration files.
    - Revert your `$HOME` directory to its original state if needed.
