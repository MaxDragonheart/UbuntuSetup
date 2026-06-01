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
- `qgis_installation.sh`: QGIS installer with a selectable `Latest Release` or `Long Term Release` repository flow.
- `nvidia_gpu_runtime_setup.sh`: mode-based NVIDIA driver/runtime diagnostics, repair, CUDA guidance, and optional Docker GPU setup.

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

## NVIDIA GPU Runtime

`nvidia_gpu_runtime_setup.sh` is intentionally mode-based. Running it without a mode does not install drivers, CUDA, or Docker GPU support.

Safe order:

```bash
bash ../artifacts/PRP-003_parallelization_readiness_check.sh
./nvidia_gpu_runtime_setup.sh diagnose
./nvidia_gpu_runtime_setup.sh list-drivers
RUN_FULL_UPGRADE=0 ./nvidia_gpu_runtime_setup.sh install-driver
sudo reboot
./nvidia_gpu_runtime_setup.sh verify-driver
./nvidia_gpu_runtime_setup.sh print-cuda-guidance
```

Use Ubuntu-supported driver tooling by default:

```bash
./nvidia_gpu_runtime_setup.sh install-driver
```

To install a specific Ubuntu driver branch shown by `list-drivers`:

```bash
./nvidia_gpu_runtime_setup.sh install-driver 550
NVIDIA_DRIVER_PROFILE=gpgpu ./nvidia_gpu_runtime_setup.sh install-driver 550-server
```

Reboot after driver install or repair before trusting `nvidia-smi`, `/dev/nvidia*`, or `/dev/dri`. Secure Boot can block unsigned NVIDIA kernel modules; Ubuntu's `ubuntu-drivers` path prefers pre-built signed modules when available.

CUDA Toolkit is separate from the NVIDIA driver runtime. Install CUDA Toolkit only when a project needs development tools such as `nvcc`, CUDA headers, or native CUDA compilation. Python GPU libraries such as `torch`, `cupy`, `numba`, `tensorflow`, and `dask` belong in the relevant project virtual environment, not in the global Ubuntu setup.

Docker GPU workloads are optional and require a working host driver first:

```bash
./nvidia_gpu_runtime_setup.sh install-container-toolkit
./nvidia_gpu_runtime_setup.sh verify-docker-gpu
```

`verify-docker-gpu` runs a temporary `docker run --rm --gpus all ... nvidia-smi` check. If it pulls the configured test image only for that check, the script removes it afterward unless `KEEP_DOCKER_GPU_TEST_IMAGE=1` is set.

## QGIS Release Choice

`qgis_installation.sh` follows the official QGIS Debian/Ubuntu installation guide:

```text
https://qgis.org/resources/installation-guide/#debian--ubuntu
```

Interactive mode asks which QGIS release line to install:

- `Latest Release`: uses `https://qgis.org/ubuntu`.
- `Long Term Release`: uses `https://qgis.org/ubuntu-ltr`.

For noninteractive use, pass the release label as an argument:

```bash
./qgis_installation.sh "Latest Release"
./qgis_installation.sh "Long Term Release"
```

or set `QGIS_RELEASE`:

```bash
QGIS_RELEASE="Latest Release" ./qgis_installation.sh
QGIS_RELEASE="Long Term Release" ./qgis_installation.sh
```

The script detects the Ubuntu suite with `lsb_release -cs`. On Ubuntu derivatives, it falls back to `UBUNTU_CODENAME` from `/etc/os-release` when available. It writes `/etc/apt/sources.list.d/qgis.sources` with the detected suite and the selected QGIS repository.

The script installs `qgis qgis-plugin-grass python3-qgis`. `python3-qgis` is kept to preserve the previous workstation behavior and provide QGIS Python bindings used by the Python console and plugins. If QGIS or GRASS packages are already installed, the script warns before continuing; it does not remove packages automatically.

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
