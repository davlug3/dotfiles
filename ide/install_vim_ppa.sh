#!/bin/bash


echo "Adding vim repositories of jonathonf..."
add-apt-repository ppa:jonathonf/vim
apt update
apt install -y vim

echo "Vim installed"
vim --version


