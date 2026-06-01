#!/usr/bin/env bash
set -euo pipefail

echo "==> Install PostgreSQL/PostGIS and DBeaver | START"

export DEBIAN_FRONTEND=noninteractive
RUN_FULL_UPGRADE="${RUN_FULL_UPGRADE:-1}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"
POSTGRES_MAJOR="${POSTGRES_MAJOR:-16}"
POSTGRES_CLUSTER="${POSTGRES_CLUSTER:-main}"
INSTALL_DBEAVER="${INSTALL_DBEAVER:-1}"

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

validate_postgres_major() {
  if [[ ! "${POSTGRES_MAJOR}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: POSTGRES_MAJOR must be a numeric PostgreSQL major version." >&2
    exit 1
  fi
}

cluster_status() {
  pg_lsclusters -h \
    | awk -v version="${POSTGRES_MAJOR}" -v cluster="${POSTGRES_CLUSTER}" \
        '$1 == version && $2 == cluster {print $4; found = 1} END {if (!found) exit 1}'
}

ensure_postgres_cluster() {
  local status

  if ! status="$(cluster_status)"; then
    echo "==> Create PostgreSQL ${POSTGRES_MAJOR}/${POSTGRES_CLUSTER} cluster"
    sudo pg_createcluster "${POSTGRES_MAJOR}" "${POSTGRES_CLUSTER}" --start
    return
  fi

  if [[ "${status}" != "online" ]]; then
    echo "==> Start PostgreSQL ${POSTGRES_MAJOR}/${POSTGRES_CLUSTER} cluster"
    sudo pg_ctlcluster "${POSTGRES_MAJOR}" "${POSTGRES_CLUSTER}" start
  else
    echo "==> PostgreSQL ${POSTGRES_MAJOR}/${POSTGRES_CLUSTER} cluster is already online"
  fi
}

validate_postgres_major
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
# Install PostgreSQL + PostGIS 3 for one explicit major version
# -------------------------------
echo "==> Install PostgreSQL ${POSTGRES_MAJOR} + PostGIS 3"
sudo apt -y install \
  "postgresql-${POSTGRES_MAJOR}" \
  "postgresql-client-${POSTGRES_MAJOR}" \
  "postgresql-${POSTGRES_MAJOR}-postgis-3"

ensure_postgres_cluster
pg_lsclusters

# -------------------------------
# Configure postgres user
# -------------------------------
echo "==> Configure postgres user password"
require_postgres_password
POSTGRES_PASSWORD_SQL="$(escape_sql_literal "${POSTGRES_PASSWORD}")"
sudo -u postgres psql \
  --cluster "${POSTGRES_MAJOR}/${POSTGRES_CLUSTER}" \
  --dbname postgres \
  --set=ON_ERROR_STOP=1 <<SQL
ALTER ROLE postgres WITH ENCRYPTED PASSWORD '${POSTGRES_PASSWORD_SQL}';
SQL
unset POSTGRES_PASSWORD_SQL

echo "==> Add PostGIS extension to PostgreSQL ${POSTGRES_MAJOR}/${POSTGRES_CLUSTER} database 'postgres'"
sudo -u postgres psql \
  --cluster "${POSTGRES_MAJOR}/${POSTGRES_CLUSTER}" \
  --dbname postgres \
  --set=ON_ERROR_STOP=1 \
  --command "CREATE EXTENSION IF NOT EXISTS postgis;"

# -------------------------------
# DBeaver (snap)
# -------------------------------
if [[ "${INSTALL_DBEAVER}" == "1" ]]; then
  echo "==> Install DBeaver CE (classic Snap)"
  sudo snap install dbeaver-ce --classic
else
  echo "==> Skip DBeaver CE installation (INSTALL_DBEAVER=${INSTALL_DBEAVER})"
fi

echo "==> Install PostgreSQL/PostGIS and DBeaver | END"

echo "---------------------------------------------------"
echo "The PostgreSQL 'postgres' password was set from POSTGRES_PASSWORD or from the interactive prompt."
echo "PostgreSQL target cluster: ${POSTGRES_MAJOR}/${POSTGRES_CLUSTER}"
echo "---------------------------------------------------"
