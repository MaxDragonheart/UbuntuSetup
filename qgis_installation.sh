#!/bin/bash

echo "Install QGIS | START"
sudo apt update && sudo apt upgrade -y

sudo apt install gnupg software-properties-common

sudo mkdir -m755 -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg
sudo cp qgis.sources /etc/apt/sources.list.d/

sudo apt update -y
sudo apt install -y qgis qgis-plugin-grass

echo "Install QGIS | END"
qgis --version
