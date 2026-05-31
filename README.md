# Ubuntu Setup

Personal Ubuntu setup scripts for reinstalling a development and desktop software stack.

The scripts are maintained for Ubuntu workstation setup and can modify packages, APT repositories, services, user groups, and desktop applications. Review a script before running it on a real machine.

## Scripts

- `development_setup.sh`: base packages, Git, Python tooling, pipx, Poetry, GIS libraries, and Docker.
- `db_stuffs_installation.sh`: PostgreSQL/PostGIS and DBeaver CE.
- `developer_software_installation.sh`: PyCharm, Visual Studio Code, Insomnia, FileZilla, and GitHub Desktop.
- `google_chrome_installation.sh`: Google Chrome stable.
- `video_and_media.sh`: codecs, VLC, OBS Studio, Kdenlive, GIMP, and Inkscape.
- `virtualbox_installation.sh`: Oracle VirtualBox and optional Extension Pack.
- `estrai_zip.sh`: extracts `.zip` files in a selected folder.
- `update_upgrade.sh`: runs `apt update`, `apt upgrade`, and `apt autoremove`.
- `qgis_installation.sh`: QGIS installer. Its release-selection flow is tracked separately and is intentionally not changed by the non-QGIS maintenance pass.

## Run A Script

Make a script executable if needed:

```bash
chmod +x filename.sh
```

Run scripts as separate processes:

```bash
./filename.sh
```

or:

```bash
bash filename.sh
```

Do not source installer scripts with `. ./filename.sh` unless the script explicitly says it must modify the current shell.

## Full System Upgrade

Installer scripts run a full system upgrade by default before installing packages:

```bash
sudo apt -y full-upgrade
```

To skip that step when supported:

```bash
RUN_FULL_UPGRADE=0 ./development_setup.sh
```

Skipping the full upgrade can reduce surprise during testing, but package installation may fail on outdated systems.

## PostgreSQL Password

`db_stuffs_installation.sh` installs PostgreSQL/PostGIS for one explicit PostgreSQL major version. The default is PostgreSQL 16:

```bash
POSTGRES_MAJOR=16 ./db_stuffs_installation.sh
```

The script no longer sets the `postgres` password to a hard-coded value. Run it interactively and enter the password when prompted, or set it explicitly:

```bash
POSTGRES_PASSWORD='change-me' ./db_stuffs_installation.sh
```

For validation environments where Snap/DBeaver should be skipped:

```bash
INSTALL_DBEAVER=0 POSTGRES_PASSWORD='change-me' ./db_stuffs_installation.sh
```

Use a real private password on production machines.

When `INSTALL_DBEAVER=1`, DBeaver CE is installed as a classic Snap because the published Snap package requires classic confinement:

```bash
sudo snap install dbeaver-ce --classic
```

## VirtualBox Extension Pack

`virtualbox_installation.sh` installs VirtualBox first. The Oracle Extension Pack is optional and requires accepting Oracle's license.

Interactive mode asks before installing the Extension Pack. For noninteractive use:

```bash
INSTALL_VIRTUALBOX_EXTPACK=0 ./virtualbox_installation.sh
INSTALL_VIRTUALBOX_EXTPACK=1 ./virtualbox_installation.sh
```

After VirtualBox setup, log out and log back in, or reboot, so the `vboxusers` group change takes effect.

## Validation

Before changing scripts, run:

```bash
bash -n *.sh
shellcheck *.sh
```

Docker tests can catch package and repository issues early, but they do not prove hardware, GUI, Snap, systemd, VirtualBox, Docker Engine, GPU, reboot, or user-group behavior. Use a clean VM matching the target Ubuntu release before relying on these scripts for a full PC reinstall.
