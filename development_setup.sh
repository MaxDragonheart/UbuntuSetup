#!/bin/bash

echo "Install develop setting up | START"
sudo apt update && sudo apt upgrade -y

echo "Install base packages"
sudo apt install -y curl

echo "--> Install Git"
sudo apt install -y git

echo "--> Install Python's packages for developing"
python3 -V
sudo apt install -y python3-pip python3-venv build-essential libssl-dev libffi-dev python3-dev binutils libproj-dev gdal-bin

echo "--> Update pip"
pip3 install --upgrade pip
export PATH="/home/max/.local/bin:$PATH"

echo "--> Install Poetry"
curl -s https://install.python-poetry.org | python3 -
export PATH="/home/max/.local/bin:$PATH"

echo "Install develop setting up | END"
