#!/bin/bash

echo "Install PostgreSQL/PostGIS pgAdmin4 Dbeaver | START"
sudo apt update && sudo apt upgrade -y

echo "--> Install PostreSQL"
sudo apt install wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt update && sudo apt upgrade -y
sudo apt install -y postgresql postgresql-contrib

echo "--> Install PostGIS"
sudo apt install -y postgis

echo "--> Install pgAdmin4"
sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
sudo curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add
sudo apt update && sudo apt upgrade -y
sudo apt install -y pgadmin4

echo "--> Install Dbeaver"
sudo snap install dbeaver-ce

echo "Install PostgreSQL/PostGIS pgAdmin4 Dbeaver | END"
