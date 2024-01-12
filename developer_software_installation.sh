#!/bin/bash

echo "Install IDE | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install PyCharm"
read -p 'Choose your PyCharm Edition: Professional[0] or Community[1]: ' PYCHARM_EDITION
if [[ $PYCHARM_EDITION -eq 0 ]] 
then
	sudo snap install pycharm-professional --classic
elif [[ $PYCHARM_EDITION -eq 1 ]] 
then
	sudo snap install pycharm-community --classic
else
	echo "Wrong choise, PyCharm doesn't installed".
fi

echo "--> Install Visual Studio Code"
sudo snap install code --classic

echo "--> Install Insomnia"
sudo snap install insomnia

echo "--> Install FileZilla"
sudo apt install -y filezilla

echo "--> Install GitHub Desktop"
wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey | gpg --dearmor | sudo tee /etc/apt/keyrings/mwt-desktop.gpg > /dev/null
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list'
sudo apt update
sudo apt install github-desktop

echo "Install IDE | END"
