#!/bin/bash

echo "Installing your dotfiles..."
cd ~ || { echo "Failed to change to home directory."; exit 1; }
git init || { echo "Failed to initialize Git repository."; exit 1; }
git remote add origin someorigin || { echo "Failed to add remote repository."; exit 1; }
git fetch origin || { echo "Failed to fetch from remote repository."; exit 1; }
git checkout -f main || { echo "Failed to checkout to main branch."; exit 1; }
echo "Successfully installled dotfiles"

