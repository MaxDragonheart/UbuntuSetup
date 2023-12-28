#!/bin/bash

echo "Install video&media | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install media codecs"
sudo apt install ubuntu-restricted-extras -y

echo "--> Install VLC"
sudo add-apt-repository ppa:videolan/stable-daily -y
sudo apt-get update -y
sudo apt install vlc -y

echo "--> Install OBS Studio"
sudo apt install obs-studio -y

echo "--> Install Kdenlive"
sudo add-apt-repository ppa:kdenlive/kdenlive-stable -y
sudo apt-get update -y
sudo apt install kdenlive -y

echo "--> Install GIMP"
sudo apt install gimp -y

echo "--> Install Inkscape"
sudo apt install inkscape -y

echo "Install video&media | END"
