#!/usr/bin/env bash
set -euo pipefail

echo "==> Install PostgreSQL/PostGIS and DBeaver | START"

export DEBIAN_FRONTEND=noninteractive
RUN_FULL_UPGRADE="${RUN_FULL_UPGRADE:-1}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"

run_full_upgrade() {
  if [[ "${RUN_FULL_UPGRADE}" == "1" ]]; then
    echo "==> Full system upgrade (set RUN_FULL_UPGRADE=0 to skip)"
    sudo apt -y full-upgrade
  else
    echo "==> Skip full system upgrade (RUN_FULL_UPGRADE=${RUN_FULL_UPGRADE})"
  fi
}

require_postgres_password() {
  if [[ -n "${POSTGRES_PASSWORD}" ]]; then
    return
  fi

  if [[ -t 0 ]]; then
    read -r -s -p "Enter password for PostgreSQL user 'postgres': " POSTGRES_PASSWORD
    echo
  else
    echo "ERROR: set POSTGRES_PASSWORD before running this script non-interactively." >&2
    exit 1
  fi

  if [[ -z "${POSTGRES_PASSWORD}" ]]; then
    echo "ERROR: PostgreSQL password cannot be empty." >&2
    exit 1
  fi
}

escape_sql_literal() {
  printf "%s" "$1" | sed "s/'/''/g"
}

sudo apt update
run_full_upgrade
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
require_postgres_password
POSTGRES_PASSWORD_SQL="$(escape_sql_literal "${POSTGRES_PASSWORD}")"
sudo -u postgres psql --set=ON_ERROR_STOP=1 <<SQL
ALTER ROLE postgres WITH ENCRYPTED PASSWORD '${POSTGRES_PASSWORD_SQL}';
SQL
unset POSTGRES_PASSWORD_SQL

echo "==> Add PostGIS extension to default 'postgres' database"
sudo -u postgres psql -d postgres -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# -------------------------------
# DBeaver (snap)
# -------------------------------
echo "==> Install DBeaver CE"
sudo snap install dbeaver-ce

echo "==> Install PostgreSQL/PostGIS and DBeaver | END"

echo "---------------------------------------------------"
echo "The PostgreSQL 'postgres' password was set from POSTGRES_PASSWORD or from the interactive prompt."
echo "---------------------------------------------------"
