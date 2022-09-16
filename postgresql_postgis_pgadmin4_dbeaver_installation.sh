#!/bin/bash

echo "Install PostgreSQL/PostGIS pgAdmin4 Dbeaver | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install PostreSQL"
sudo apt install wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt>
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -c>
sudo apt update && sudo apt upgrade -y
sudo apt install -y postgresql postgresql-contrib

echo "--> Install PostGIS"
sudo apt install -y postgis

echo "--> Install pgAdmin4"
sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb>
sudo curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-ke>
sudo apt update && sudo apt upgrade -y
sudo apt install -y pgadmin4

echo "--> Install Dbeaver"
sudo snap install dbeaver-ce

echo "Install PostgreSQL/PostGIS pgAdmin4 Dbeaver | END"
