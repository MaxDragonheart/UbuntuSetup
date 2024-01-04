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

echo "Install IDE | END"
