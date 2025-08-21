#!/usr/bin/env bash
set -euo pipefail

echo "==> Install IDE | START"

export DEBIAN_FRONTEND=noninteractive

sudo apt update
sudo apt -y full-upgrade
sudo apt -y install ca-certificates curl gnupg

# Assicurati che snapd sia attivo (per PyCharm/Insomnia)
sudo systemctl enable --now snapd || true

# -------------------------------
# PyCharm (snap) - 0=Pro, 1=Community
# -------------------------------
PYCHARM_EDITION="${1:-}"   # Passa 0 o 1 come argomento per evitare la domanda
if [[ -z "${PYCHARM_EDITION}" ]]; then
  read -r -p 'Choose PyCharm Edition: Professional[0] or Community[1] (default 1): ' PYCHARM_EDITION
  PYCHARM_EDITION="${PYCHARM_EDITION:-1}"
fi

if [[ "${PYCHARM_EDITION}" == "0" ]]; then
  sudo snap install pycharm-professional --classic
elif [[ "${PYCHARM_EDITION}" == "1" ]]; then
  sudo snap install pycharm-community --classic
else
  echo "-> Invalid choice, skipping PyCharm."
fi

# -------------------------------
# Visual Studio Code (APT repo Microsoft)
# -------------------------------
echo "==> Visual Studio Code (Microsoft APT repo)"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg

echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

sudo apt update
sudo apt -y install code

# -------------------------------
# Insomnia (snap)
# -------------------------------
echo "==> Insomnia (snap)"
sudo snap install insomnia

# -------------------------------
# FileZilla (APT)
# -------------------------------
echo "==> FileZilla"
sudo apt -y install filezilla

# -------------------------------
# GitHub Desktop (Shiftkey APT repo)
# -------------------------------
echo "==> GitHub Desktop (Shiftkey)"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://mirror.mwt.me/shiftkey-desktop/gpgkey \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/mwt-desktop.gpg > /dev/null
sudo chmod a+r /etc/apt/keyrings/mwt-desktop.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" \
  | sudo tee /etc/apt/sources.list.d/mwt-desktop.list > /dev/null

sudo apt update
sudo apt -y install github-desktop

# -------------------------------
# Versions
# -------------------------------
echo "==> Versions"
code --version || true
insomnia --version || true
github-desktop --version || true
snap version || true

echo "==> Install IDE | END"
