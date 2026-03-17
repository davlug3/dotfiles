if [ -f /etc/skel/.bashrc ]; then
	source /etc/skel/.bashrc
fi


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# install terminfo file
TERMINFO_FILE="/usr/share/terminfo/x/xterm-256color"

if [ ! -e "$TERMINFO_FILE" ] && [ ! -e "/lib/terminfo/x/xterm-256color" ]; then
    echo "xterm-256color terminfo not found. Attempting to install..."
    
    if command -v apk >/dev/null; then
        apk add ncurses-terminfo-base
    elif command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y ncurses-term
    elif command -v dnf >/dev/null; then
        sudo dnf install -y ncurses-term
    elif command -v yum >/dev/null; then
        sudo yum install -y ncurses-term
    fi
fi

if [ -e "$TERMINFO_FILE" ] || [ -e "/lib/terminfo/x/xterm-256color" ]; then
    export TERM='xterm-256color'
fi
export PATH="$HOME/.ddbin:$PATH"

