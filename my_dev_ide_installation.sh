#!/bin/bash

echo "Install IDE | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install PyCharm"
sudo snap install pycharm-professional --classic

echo "--> Install Visual Studio Code"
sudo snap install code --classic

echo "Install IDE | END"
