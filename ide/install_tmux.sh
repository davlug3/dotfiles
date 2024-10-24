#!/bin/bash
add-apt-repository ppa:tmux/tmux
apt update
apt install -y tmux

tmux -V

echo "TMUX installed"
