#!/usr/bin/env bash
set -euo pipefail

echo "==> Install QGIS | START"

export DEBIAN_FRONTEND=noninteractive

# Aggiorna sistema
sudo apt update
sudo apt -y full-upgrade
sudo apt -y install wget curl gnupg software-properties-common

# Keyring QGIS
sudo install -d -m 0755 /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/qgis-archive-keyring.gpg

# Repository QGIS LTR (per Ubuntu 24.04 Noble)
cat <<EOF | sudo tee /etc/apt/sources.list.d/qgis.sources > /dev/null
Types: deb deb-src
URIs: https://qgis.org/ubuntu-ltr
Suites: noble
Architectures: amd64
Components: main
Signed-By: /etc/apt/keyrings/qgis-archive-keyring.gpg
EOF

# Aggiorna repo e installa QGIS
sudo apt update
sudo apt -y install qgis qgis-plugin-grass python3-qgis

echo "==> Install QGIS | END"
qgis --version
