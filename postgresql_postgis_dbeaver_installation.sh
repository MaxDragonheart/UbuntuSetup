sudo s#!/bin/bash

echo "Install PostgreSQL/PostGIS and Dbeaver | START"
sudo apt update && sudo apt upgrade -y

echo "--> Create the file repository configuration"
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

echo "--> Import the repository signing key"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

echo "--> Install PostreSQL 16"
sudo apt install -y postgresql-16 postgresql-contrib

echo "--> Install PostGIS 3 for PostgreSQL 16"
sudo apt install -y postgresql-16-postgis-3

echo "--> Create postgres' user password"
sudo -u postgres psql -c "alter role postgres with encrypted password 'postgres';"

echo "--> Add PostGIS extension to default PostgreSQL DB"
sudo -u postgres psql -c "create extension postgis;"

echo "--> Install Dbeaver"
sudo snap install dbeaver-ce

echo "Install PostgreSQL/PostGIS and Dbeaver | END"

echo "..."
echo "Don't forgot to change password of postgres user!"
echo "Don't forgot to change password of postgres user!!"
echo "Don't forgot to change password of postgres user!!!"
