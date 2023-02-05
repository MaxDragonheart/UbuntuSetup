#!/bin/bash

echo "Install IDE | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install PyCharm"
sudo snap install pycharm-community --classic

echo "--> Install Atom"
sudo apt install software-properties-common apt-transport-https wget ubuntu-keyring gnupg2 -y
sudo wget -O- https://packagecloud.io/AtomEditor/atom/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/atom.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/atom.gpg] https://packagecloud.io/AtomEditor/atom/any/ any main" | sudo tee /etc/apt/sources.list.d/atom.list
sudo apt update -y
sudo apt install atom -y

echo "Install IDE | END"
