#!/bin/bash

echo "Install VLC and media codec | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install media codecs"
sudo apt install ubuntu-restricted-extras

echo "--> Install VLC"
sudo add-apt-repository ppa:videolan/stable-daily -y
sudo apt-get update -y
sudo apt install vlc -y

echo "Install VLC and media codec | END"
