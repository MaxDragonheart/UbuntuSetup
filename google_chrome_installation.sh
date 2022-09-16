#!/bin/bash

# Steps from: https://www.linuxcapable.com/how-to-install-google-chrome-on-ubuntu-20-04/

echo "--> Google Chrome installation | START"

sudo apt update && sudo apt upgrade -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common wget -y
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
sudo apt update
sudo apt install google-chrome-stable -y

echo  "--> Google Chrome installation | END"
google-chrome --version
