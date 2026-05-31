#!/usr/bin/env bash
set -euo pipefail

echo "--> Google Chrome installation | START"

export DEBIAN_FRONTEND=noninteractive
RUN_FULL_UPGRADE="${RUN_FULL_UPGRADE:-1}"

run_full_upgrade() {
  if [[ "${RUN_FULL_UPGRADE}" == "1" ]]; then
    echo "==> Full system upgrade (set RUN_FULL_UPGRADE=0 to skip)"
    sudo apt -y full-upgrade
  else
    echo "==> Skip full system upgrade (RUN_FULL_UPGRADE=${RUN_FULL_UPGRADE})"
  fi
}

# 1) Aggiorna base (apt-transport-https non serve più su Ubuntu recenti)
sudo apt update
run_full_upgrade
sudo apt -y install curl ca-certificates gnupg

# 2) Prepara la cartella dei keyring se non esiste
sudo install -m 0755 -d /etc/apt/keyrings

# 3) Installa/aggiorna la chiave Google nel keyring (formato dearmored)
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg

# Permessi lettura per apt
sudo chmod a+r /etc/apt/keyrings/google-chrome.gpg

# 4) Registra il repository (idempotente)
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# 5) Installa Chrome stabile
sudo apt update
sudo apt -y install google-chrome-stable

echo "--> Google Chrome installation | END"
google-chrome --version
