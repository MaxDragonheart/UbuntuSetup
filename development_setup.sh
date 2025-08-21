#!/usr/bin/env bash
set -euo pipefail

echo "==> Development setup | START"

export DEBIAN_FRONTEND=noninteractive

# -----------------------------
# 1) Sistema base
# -----------------------------
echo "==> Update base system"
sudo apt update
sudo apt -y full-upgrade
sudo apt -y autoremove

echo "==> Install base packages"
sudo apt -y install \
  curl wget unzip gettext ca-certificates gnupg \
  build-essential pkg-config

echo "==> Git"
sudo apt -y install git

# -----------------------------
# 2) Toolchain Python (senza rompere il Python di sistema)
# -----------------------------
echo "==> Python toolchain (apt)"
python3 -V
sudo apt -y install python3-pip python3-venv python3-dev libssl-dev libffi-dev binutils

# Assicura ~/.local/bin nel PATH (ora e future shell)
export PATH="$HOME/.local/bin:$PATH"
grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"

# pipx per strumenti utente (poetry, ruff, pre-commit, ecc.)
echo "==> pipx (user-level tools)"
sudo apt -y install pipx
pipx ensurepath

# Poetry via pipx (consigliato su Ubuntu 24.04)
echo "==> Install Poetry via pipx"
pipx install poetry

# (NOTA) Aggiornare pip/wheel/setuptools SOLO dentro i virtualenv dei progetti:
#   python3 -m venv .venv && source .venv/bin/activate
#   pip install -U pip wheel setuptools

# -----------------------------
# 3) Librerie GIS
# -----------------------------
echo "==> GIS libraries (GDAL/PROJ/GEOS/PostgreSQL client headers)"
sudo apt -y install \
  libpq-dev libproj-dev proj-data proj-bin libgeos-dev \
  gdal-bin python3-gdal libgdal-dev

# -----------------------------
# 4) Docker (repo ufficiale)
# -----------------------------
echo "==> Docker (engine, buildx, compose)"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

source /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# avvia ed abilita
sudo systemctl enable --now docker
# abilita uso senza sudo (richiede logout/login o reboot)
sudo usermod -aG docker "$USER"

# -----------------------------
# 5) Versioni utili a schermo
# -----------------------------
echo "==> Versions"
git --version || true
python3 -V
pipx --version || true
poetry --version || true
gdalinfo --version || true
docker --version || true
docker compose version || true

echo "==> Development setup | END"
echo "NOTE: esegui logout/login (o reboot) per usare Docker senza sudo (nuovo gruppo 'docker')."
echo "NOTE: usa 'python3 -m venv .venv && source .venv/bin/activate' nei progetti; aggiorna pip/wheel dentro il venv."
