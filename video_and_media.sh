#!/usr/bin/env bash
set -euo pipefail

echo "==> Install video & media | START"

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

sudo apt update
run_full_upgrade

# -------------------------------
# Multimedia codecs
# -------------------------------
echo "==> Install media codecs (MP3, MP4, etc.)"
sudo apt -y install ubuntu-restricted-extras

# -------------------------------
# VLC (repo ufficiale)
# -------------------------------
echo "==> Install VLC"
sudo apt -y install vlc

# -------------------------------
# OBS Studio (repo ufficiale, già recente su 24.04)
# -------------------------------
echo "==> Install OBS Studio"
sudo apt -y install obs-studio

# -------------------------------
# Kdenlive (repo ufficiale, stabile su 24.04)
# -------------------------------
echo "==> Install Kdenlive"
sudo apt -y install kdenlive

# -------------------------------
# GIMP (repo ufficiale)
# -------------------------------
echo "==> Install GIMP"
sudo apt -y install gimp

# -------------------------------
# Inkscape (repo ufficiale)
# -------------------------------
echo "==> Install Inkscape"
sudo apt -y install inkscape

echo "==> Install video & media | END"
