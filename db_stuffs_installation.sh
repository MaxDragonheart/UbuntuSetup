#!/usr/bin/env bash
set -euo pipefail

echo "==> Install PostgreSQL/PostGIS and DBeaver | START"

export DEBIAN_FRONTEND=noninteractive

sudo apt update
sudo apt -y full-upgrade
sudo apt -y install wget curl ca-certificates gnupg lsb-release

# -------------------------------
# PostgreSQL Global Development Group (PGDG) repository
# -------------------------------
echo "==> Configure PostgreSQL APT repository"

# keyrings dir
sudo install -m 0755 -d /etc/apt/keyrings

# import key (dearmored)
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/postgres.gpg > /dev/null
sudo chmod a+r /etc/apt/keyrings/postgres.gpg

# add repo
CODENAME="$(lsb_release -cs)"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/postgres.gpg] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

sudo apt update

# -------------------------------
# Install PostgreSQL 16 + contrib + PostGIS 3
# -------------------------------
echo "==> Install PostgreSQL 16 + PostGIS 3"
sudo apt -y install postgresql-16 postgresql-contrib postgresql-16-postgis-3

# -------------------------------
# Configure postgres user
# -------------------------------
echo "==> Configure postgres user password"
sudo -u postgres psql -c "ALTER ROLE postgres WITH ENCRYPTED PASSWORD 'postgres';"

echo "==> Add PostGIS extension to default 'postgres' database"
sudo -u postgres psql -d postgres -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# -------------------------------
# DBeaver (snap)
# -------------------------------
echo "==> Install DBeaver CE"
sudo snap install dbeaver-ce

echo "==> Install PostgreSQL/PostGIS and DBeaver | END"

echo "---------------------------------------------------"
echo "!! Remember to change the password of 'postgres' user !!"
echo "---------------------------------------------------"
