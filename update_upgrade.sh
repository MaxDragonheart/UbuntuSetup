#!/usr/bin/env bash
set -euo pipefail

echo "Update ...."
sudo apt update -y
echo "Done!"
echo "Upgrade ..."
sudo apt upgrade -y
echo "Done!"
echo "Autoremove ..."
sudo apt autoremove -y
echo "Done!"
echo "Process completed!"
