#!/bin/bash

echo "Install develop setting up | START"
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

echo "Install base packages"
sudo apt install -y curl
sudo apt install -y wget
sudo apt install -y unzip

echo "--> Install Git"
sudo apt install -y git

echo "--> Install Python's packages for developing"
python3 -V
sudo apt install -y python3-pip python3-venv python3-dev build-essential libssl-dev libffi-dev binutils

echo "--> Update pip"
pip3 install --upgrade pip
export PATH="/home/max/.local/bin:$PATH"
pip3 install --upgrade wheel

echo "--> Install Python's packages for GIS developing"
sudo apt install -y libpq-dev libproj-dev proj-data proj-bin libgeos-dev
sudo DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
sudo apt install -y tzdata libgdal-dev python3-gdal gdal-bin

echo "--> Install Poetry"
curl -s https://install.python-poetry.org | python3 -
export PATH="/home/max/.local/bin:$PATH"

echo "Install develop setting up | END"
