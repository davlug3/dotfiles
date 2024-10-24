#!/bin/bash


git clone https://github.com/vim/vim.git

cd vim

apt install -y git  make clang libtool-bin

cd src


echo "Compiling and installing vim..."
make

echo "Testing"
make test
make install

apt install -y libxt-dev
make reconfig

apt install -y libpython3-dev
make reconfig CONV_OPT_PYTHON3=--"enable-python3interp"



vim --version | head -n 5A


echo "Vim installed"
