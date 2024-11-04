#!/bin/bash
echo "Installing your dotfiles..."
cd ~ || { echo "Failed to change to home directory."; exit 1; }
git init || { echo "Failed to initialize Git repository."; exit 1; }
git remote add origin ${DOTFILES_URL} 
git fetch origin || { echo "Failed to fetch from remote repository."; exit 1; }
git checkout -f git || { echo "Failed to checkout to git branch."; exit 1; }
echo "Successfully installled dotfiles"
echo "pwd is $(pwd)"
