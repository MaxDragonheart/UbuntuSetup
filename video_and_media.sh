#!/usr/bin/env bash
set -euo pipefail

echo "==> Install video & media | START"

export DEBIAN_FRONTEND=noninteractive

sudo apt update
sudo apt -y full-upgrade

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
