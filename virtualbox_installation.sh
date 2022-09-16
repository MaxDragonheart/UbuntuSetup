#!/bin/bash

# Steps from: https://computingforgeeks.com/install-virtualbox-6-on-ubuntu-linux/

echo "Install VirtualBox | START"
sudo apt update && sudo apt upgrade -y

echo "--> Import VirtualBox 6.1 apt repository GPG Keys"
curl https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor > oracle_vbox_2016.gpg
curl https://www.virtualbox.org/download/oracle_vbox.asc | gpg --dearmor > oracle_vbox.gpg
sudo install -o root -g root -m 644 oracle_vbox_2016.gpg /etc/apt/trusted.gpg.d/
sudo install -o root -g root -m 644 oracle_vbox.gpg /etc/apt/trusted.gpg.d/

echo "--> Add the VirtualBox 6.1 Repository on Ubuntu"
echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee>

sudo apt update -y
sudo apt install -y linux-headers-$(uname -r) dkms
sudo apt install -y virtualbox-6.1

echo "Install VirtualBox | END"
