#!/bin/bash


# Parse command-line arguments
ask=1
for arg in "$@"; do
    if [ "$arg" == "-y" ] || [ "$arg" == "--yes" ]; then
        ask=0
        break
    fi
done

# Ask for confirmation if not using -y or --yes
if (( ask != 0 )); then
    echo -n "Do you want to continue? (y/n): "
    read -r response </dev/tty
    if [[ "${response,,}" != "y" ]]; then
        echo "Exiting..."
        exit 1
    fi
fi

# Set default DOTFILES_URL if not provided
if [ -z "$DOTFILES_URL" ]; then
    export DOTFILES_URL=https://github.com/davlug3/dotfiles
fi

# Extract repository name from DOTFILES_URL
REPO_NAME="${DOTFILES_URL#*github.com/}"

# Check if Git is installed
if command -v git >/dev/null 2>&1; then
    echo "Git is already installed."
else
    echo "Git is not installed. Checking for install_git.sh..."

    # Check for existing install_git.sh
    if [ -f "$(pwd)/install_git.sh" ]; then
        echo "install_git.sh found. Running..."
	bash "$(pwd)/install_git.sh" || { echo "install_git.sh failed."; exit 1; } 
    else
        echo "install_git.sh not found. Downloading..."
	curl -o "$(pwd)/install_git.sh" "https://cdn.jsdelivr.net/gh/$REPO_NAME@git/.dotfiles/install_git.sh" || {
            echo "Failed to download install_git.sh"
            exit 1
        }
	bash "$(pwd)/install_git.sh" || {
            echo "install_git.sh failed"
            exit 1
        }
	rm "$(pwd)/install_git.sh"
    fi
fi

# Install dotfiles and related utilities
echo "Installing dotfiles..."

# Check for existing install_dotfiles.sh
if [ -f "$(pwd)/install_dotfiles.sh" ]; then
	echo "install_dotfiles.sh found. Running..."
	bash "$(pwd)/install_dotfiles.sh"
else
	echo "install_dotfiles.sh not found. Downloading..."
	curl -o "$(pwd)/install_dotfiles.sh" "https://cdn.jsdelivr.net/gh/$REPO_NAME@git/.dotfiles/install_dotfiles.sh" || {
	    echo "Failed to download install_dotfiles.sh";
	    exit 1;
	}
	echo "downloaded..."

	bash "$(pwd)/install_dotfiles.sh" || { echo "install_dotfiles.sh failed"; exit 1; }
	rm "$(pwd)/install_dotfiles.sh"
fi

echo "------------"

cd $HOME/.dotfiles
bash ./install_tmux.sh || { echo "install_tmux.sh failed"; exit 1; }
bash ./install_tpm.sh || { echo "install_tpm.sh failed"; exit 1; }

# Check the final status
echo "All scripts completed successfully."

