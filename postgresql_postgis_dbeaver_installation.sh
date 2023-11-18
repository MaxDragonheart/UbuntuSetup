sudo s#!/bin/bash

echo "Install PostgreSQL/PostGIS and Dbeaver | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install PostreSQL"
sudo apt install -y postgresql postgresql-contrib

echo "--> Install PostGIS"
sudo apt install -y postgis

echo "--> Create postgres' user password"
sudo -u postgres psql -c "alter role postgres with encrypted password 'changemesoon';"

echo "--> Add PostGIS extension to default PostgreSQL DB"
sudo -u postgres psql -c "create extension postgis;"

echo "--> Install Dbeaver"
sudo snap install dbeaver-ce

echo "Install PostgreSQL/PostGIS and Dbeaver | END"

echo "..."
echo "Don't forgot to change password of postgres user!"
echo "Don't forgot to change password of postgres user!!"
echo "Don't forgot to change password of postgres user!!!"
