#!/bin/bash

echo "Install development settings | START"
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

echo "Install base packages"
sudo apt install -y curl
sudo apt install -y wget
sudo apt install -y unzip
sudo apt install -y gettext

echo "--> Install Git"
sudo apt install -y git

echo "--> Install Python's packages for developing"
python3 -V
sudo apt install -y python3-pip python3-venv python3-dev build-essential libssl-dev libffi-dev binutils

echo "--> Update pip"
pip3 install --upgrade pip
export PATH="/home/max/.local/bin:$PATH"
pip3 install --upgrade wheel pillow setuptools

echo "--> Install Python's packages for GIS developing"
sudo apt install -y libpq-dev libproj-dev proj-data proj-bin libgeos-dev
sudo DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
sudo apt install -y tzdata libgdal-dev python3-gdal gdal-bin

echo "--> Install Poetry"
curl -s https://install.python-poetry.org | python3 -
export PATH="/home/max/.local/bin:$PATH"

echo "--> Install Docker" 
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Install development settings up | END"
