#!/usr/bin/env bash
set -euo pipefail

echo "==> Install VirtualBox (latest from Oracle) | START"

export DEBIAN_FRONTEND=noninteractive

# -------------------------------
# Base system update
# -------------------------------
sudo apt update
sudo apt -y full-upgrade
sudo apt -y install dkms build-essential linux-headers-$(uname -r) curl ca-certificates gnupg lsb-release wget

# -------------------------------
# Oracle VirtualBox repository
# -------------------------------
echo "==> Configure Oracle VirtualBox repository"

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/oracle-virtualbox.gpg > /dev/null
sudo chmod a+r /etc/apt/keyrings/oracle-virtualbox.gpg

CODENAME="$(lsb_release -cs)"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/oracle-virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian ${CODENAME} contrib" \
  | sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null

sudo apt update

# -------------------------------
# Install VirtualBox
# -------------------------------
echo "==> Install VirtualBox (7.x)"
sudo apt -y install virtualbox-7.0

# -------------------------------
# Extension Pack
# -------------------------------
echo "==> Install Extension Pack"
VERSION=$(vboxmanage --version | cut -dr -f1)
wget https://download.virtualbox.org/virtualbox/${VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VERSION}.vbox-extpack

# Accettazione licenza: interattiva!
sudo vboxmanage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-${VERSION}.vbox-extpack

# Pulizia file extpack
rm -f Oracle_VM_VirtualBox_Extension_Pack-${VERSION}.vbox-extpack

# -------------------------------
# Group for USB access
# -------------------------------
sudo usermod -aG vboxusers "$USER"

echo "==> Versions"
vboxmanage --version || true
VBoxManage list extpacks || true

echo "==> Install VirtualBox + Extension Pack | END"
echo "NOTE: fai logout/login (o reboot) per usare VirtualBox con USB (gruppo vboxusers)."
echo "NOTE: durante l'installazione dell'Extension Pack ti verrà chiesta conferma della licenza Oracle."
