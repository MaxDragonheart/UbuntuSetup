#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
RUN_FULL_UPGRADE="${RUN_FULL_UPGRADE:-1}"
QGIS_RELEASE_CHOICE="${QGIS_RELEASE:-ask}"
QGIS_RELEASE_LABEL=""
QGIS_REPOSITORY=""
CODENAME=""
CODENAME_SOURCE=""

usage() {
  cat <<'USAGE'
Usage: ./qgis_installation.sh ["Latest Release"|"Long Term Release"]

Installs QGIS from the official QGIS Ubuntu repository.

Release choices:
  Latest Release
  Long Term Release

Noninteractive examples:
  ./qgis_installation.sh "Latest Release"
  QGIS_RELEASE="Long Term Release" ./qgis_installation.sh
USAGE
}

run_full_upgrade() {
  if [[ "${RUN_FULL_UPGRADE}" == "1" ]]; then
    echo "==> Full system upgrade (set RUN_FULL_UPGRADE=0 to skip)"
    sudo apt -y full-upgrade
  else
    echo "==> Skip full system upgrade (RUN_FULL_UPGRADE=${RUN_FULL_UPGRADE})"
  fi
}

normalize_release_choice() {
  local choice="$1"
  local normalized

  normalized="${choice,,}"
  normalized="${normalized//_/ }"
  normalized="${normalized//-/ }"

  case "${normalized}" in
    1|latest|"latest release")
      QGIS_RELEASE_LABEL="Latest Release"
      QGIS_REPOSITORY="https://qgis.org/ubuntu"
      ;;
    2|ltr|longterm|"long term"|"long term release")
      QGIS_RELEASE_LABEL="Long Term Release"
      QGIS_REPOSITORY="https://qgis.org/ubuntu-ltr"
      ;;
    *)
      echo "ERROR: QGIS release must be 'Latest Release' or 'Long Term Release'." >&2
      usage >&2
      exit 1
      ;;
  esac
}

select_qgis_release() {
  if [[ "${QGIS_RELEASE_CHOICE}" == "ask" || -z "${QGIS_RELEASE_CHOICE}" ]]; then
    if [[ ! -t 0 ]]; then
      echo "ERROR: set QGIS_RELEASE or pass a release argument for noninteractive use." >&2
      usage >&2
      exit 1
    fi

    echo "Choose QGIS release:"
    echo "  1) Latest Release"
    echo "  2) Long Term Release"
    read -r -p "Selection [1-2] (default: Long Term Release): " QGIS_RELEASE_CHOICE
    QGIS_RELEASE_CHOICE="${QGIS_RELEASE_CHOICE:-2}"
  fi

  normalize_release_choice "${QGIS_RELEASE_CHOICE}"
}

is_valid_codename() {
  local codename="$1"

  [[ -n "${codename}" && "${codename}" != "n/a" && "${codename}" =~ ^[a-z][a-z0-9._-]*$ ]]
}

set_ubuntu_codename() {
  local lsb_codename=""
  local os_id=""
  local ubuntu_codename=""
  local version_codename=""

  if command -v lsb_release >/dev/null 2>&1; then
    lsb_codename="$(lsb_release -cs 2>/dev/null || true)"
  fi

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os_id="${ID:-}"
    ubuntu_codename="${UBUNTU_CODENAME:-}"
    version_codename="${VERSION_CODENAME:-}"
  fi

  if [[ -n "${os_id}" && "${os_id}" != "ubuntu" ]]; then
    if is_valid_codename "${ubuntu_codename}"; then
      CODENAME="${ubuntu_codename}"
      CODENAME_SOURCE="UBUNTU_CODENAME from /etc/os-release"
      return
    fi

    echo "ERROR: this Ubuntu installer needs an Ubuntu codename." >&2
    echo "ERROR: lsb_release returned '${lsb_codename:-unknown}', but /etc/os-release does not expose UBUNTU_CODENAME." >&2
    exit 1
  fi

  if is_valid_codename "${lsb_codename}"; then
    CODENAME="${lsb_codename}"
    CODENAME_SOURCE="lsb_release -cs"
    return
  fi

  if is_valid_codename "${ubuntu_codename}"; then
    CODENAME="${ubuntu_codename}"
    CODENAME_SOURCE="UBUNTU_CODENAME from /etc/os-release"
    return
  fi

  if is_valid_codename "${version_codename}"; then
    CODENAME="${version_codename}"
    CODENAME_SOURCE="VERSION_CODENAME from /etc/os-release"
    return
  fi

  echo "ERROR: unable to detect Ubuntu codename from lsb_release or /etc/os-release." >&2
  exit 1
}

warn_existing_qgis_grass_packages() {
  local installed_packages

  installed_packages="$(
    dpkg-query -W -f='  - ${binary:Package} ${Version}\n' \
      'qgis*' 'libqgis*' 'python3-qgis*' 'grass*' 2>/dev/null \
      | sort -u || true
  )"

  if [[ -n "${installed_packages}" ]]; then
    echo "WARNING: existing QGIS/GRASS packages are installed:"
    printf "%s\n" "${installed_packages}"
    echo "WARNING: if these packages came from another repository, the QGIS guide recommends removing them before updating."
    echo "WARNING: this script will not remove existing packages automatically."
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  echo "ERROR: expected zero or one release argument." >&2
  usage >&2
  exit 1
fi

if [[ $# -eq 1 ]]; then
  QGIS_RELEASE_CHOICE="$1"
fi

select_qgis_release
set_ubuntu_codename

echo "==> Install QGIS | START"
echo "==> QGIS release: ${QGIS_RELEASE_LABEL}"
echo "==> QGIS repository: ${QGIS_REPOSITORY}"
echo "==> Ubuntu codename: ${CODENAME} (${CODENAME_SOURCE})"
warn_existing_qgis_grass_packages

# Aggiorna sistema
sudo apt update
run_full_upgrade
sudo apt -y install wget curl gnupg software-properties-common lsb-release

# Keyring QGIS
sudo install -d -m 0755 /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/qgis-archive-keyring.gpg

# Repository QGIS
cat <<EOF | sudo tee /etc/apt/sources.list.d/qgis.sources > /dev/null
Types: deb deb-src
URIs: ${QGIS_REPOSITORY}
Suites: ${CODENAME}
Architectures: amd64
Components: main
Signed-By: /etc/apt/keyrings/qgis-archive-keyring.gpg
EOF

# Aggiorna repo e installa QGIS
sudo apt update
sudo apt -y install qgis qgis-plugin-grass python3-qgis

echo "==> Install QGIS | END"
qgis --version || true
