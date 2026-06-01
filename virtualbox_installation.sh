#!/usr/bin/env bash
set -euo pipefail

echo "==> Install VirtualBox (latest from Oracle) | START"

export DEBIAN_FRONTEND=noninteractive
RUN_FULL_UPGRADE="${RUN_FULL_UPGRADE:-1}"
INSTALL_VIRTUALBOX_EXTPACK="${INSTALL_VIRTUALBOX_EXTPACK:-ask}"

run_full_upgrade() {
  if [[ "${RUN_FULL_UPGRADE}" == "1" ]]; then
    echo "==> Full system upgrade (set RUN_FULL_UPGRADE=0 to skip)"
    sudo apt -y full-upgrade
  else
    echo "==> Skip full system upgrade (RUN_FULL_UPGRADE=${RUN_FULL_UPGRADE})"
  fi
}

should_install_extpack() {
  case "${INSTALL_VIRTUALBOX_EXTPACK}" in
    1|yes|YES|y|Y|true|TRUE)
      return 0
      ;;
    0|no|NO|n|N|false|FALSE)
      return 1
      ;;
    ask)
      if [[ ! -t 0 ]]; then
        echo "==> Skipping Extension Pack in non-interactive mode."
        echo "==> Set INSTALL_VIRTUALBOX_EXTPACK=1 to install it explicitly."
        return 1
      fi
      echo "NOTE: Oracle Extension Pack installation is interactive and requires accepting the Oracle license."
      read -r -p "Install the Oracle VirtualBox Extension Pack now? [y/N]: " EXT_PACK_REPLY
      [[ "${EXT_PACK_REPLY}" =~ ^[Yy]$ ]]
      ;;
    *)
      echo "ERROR: INSTALL_VIRTUALBOX_EXTPACK must be 1, 0, or ask." >&2
      exit 1
      ;;
  esac
}

# -------------------------------
# Base system update
# -------------------------------
sudo apt update
run_full_upgrade
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
if should_install_extpack; then
  echo "==> Install Extension Pack"
  VERSION=$(vboxmanage --version | cut -dr -f1)
  wget https://download.virtualbox.org/virtualbox/${VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VERSION}.vbox-extpack

  # Accettazione licenza: interattiva!
  sudo vboxmanage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-${VERSION}.vbox-extpack

  # Pulizia file extpack
  rm -f Oracle_VM_VirtualBox_Extension_Pack-${VERSION}.vbox-extpack
else
  echo "==> Extension Pack installation skipped."
fi

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
