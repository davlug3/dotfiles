#!bin/bash
if [ -z "${DOTFILES_URL}" ]; then
  echo "DOTFILES_URL environment variable is not set"
  exit 1
  else
        echo "MY_VARIABLE is set to ${MY_VARIABLE}"
        fi

echo "Installing your dotfiles..."


cd ~ || { echo "Failed to change to home directory."; exit 1; }
git init || { echo "Failed to initialize Git repository."; exit 1; }
git remote add origin ${DOTFILES_URL} | { echo "Failed to add remote repository."; exit 1; }
git fetch origin || { echo "Failed to fetch from remote repository."; exit 1; }
git checkout -f git || { echo "Failed to checkout to git branch."; exit 1; }
echo "Successfully installled dotfiles"

