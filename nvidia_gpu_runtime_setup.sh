#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
RUN_FULL_UPGRADE="${RUN_FULL_UPGRADE:-1}"
NVIDIA_DRIVER_PROFILE="${NVIDIA_DRIVER_PROFILE:-desktop}"
DOCKER_GPU_TEST_IMAGE="${DOCKER_GPU_TEST_IMAGE:-ubuntu:24.04}"
KEEP_DOCKER_GPU_TEST_IMAGE="${KEEP_DOCKER_GPU_TEST_IMAGE:-0}"
WARNINGS=0

usage() {
  cat <<'USAGE'
Usage: ./nvidia_gpu_runtime_setup.sh MODE [driver-branch]

Modes:
  diagnose                    Read-only GPU runtime diagnostics.
  list-drivers                Read-only Ubuntu driver discovery.
  install-driver [branch]     Install recommended NVIDIA driver, or a selected branch.
  verify-driver               Verify nvidia-smi, /dev/nvidia*, and /dev/dri.
  install-container-toolkit   Install NVIDIA Container Toolkit and configure Docker.
  verify-docker-gpu           Run a temporary Docker GPU validation container.
  print-cuda-guidance         Explain when CUDA Toolkit is needed.

Examples:
  ./nvidia_gpu_runtime_setup.sh diagnose
  ./nvidia_gpu_runtime_setup.sh list-drivers
  ./nvidia_gpu_runtime_setup.sh install-driver
  ./nvidia_gpu_runtime_setup.sh install-driver 550
  NVIDIA_DRIVER_PROFILE=gpgpu ./nvidia_gpu_runtime_setup.sh install-driver 550-server
  ./nvidia_gpu_runtime_setup.sh verify-driver
  ./nvidia_gpu_runtime_setup.sh install-container-toolkit
  ./nvidia_gpu_runtime_setup.sh verify-docker-gpu
  ./nvidia_gpu_runtime_setup.sh print-cuda-guidance

Environment:
  RUN_FULL_UPGRADE=0              Skip full-upgrade in install-driver mode.
  NVIDIA_DRIVER_PROFILE=desktop   Use ubuntu-drivers desktop install path (default).
  NVIDIA_DRIVER_PROFILE=gpgpu     Use ubuntu-drivers --gpgpu install path.
  DOCKER_GPU_TEST_IMAGE=ubuntu:24.04
  KEEP_DOCKER_GPU_TEST_IMAGE=1    Keep the test image after verify-docker-gpu.
USAGE
}

section() {
  printf '\n==> %s\n' "$1"
}

info() {
  printf '[INFO] %s\n' "$1"
}

ok() {
  printf '[ OK ] %s\n' "$1"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf '[WARN] %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

run_full_upgrade() {
  if [[ "${RUN_FULL_UPGRADE}" == "1" ]]; then
    echo "==> Full system upgrade (set RUN_FULL_UPGRADE=0 to skip)"
    sudo apt -y full-upgrade
  else
    echo "==> Skip full system upgrade (RUN_FULL_UPGRADE=${RUN_FULL_UPGRADE})"
  fi
}

require_command() {
  local command_name="$1"
  local install_hint="$2"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    die "${command_name} is required. ${install_hint}"
  fi
}

print_os_and_kernel() {
  section "OS and Kernel"

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    info "OS: ${PRETTY_NAME:-unknown}"
  else
    warn "/etc/os-release is not readable"
  fi

  info "Kernel: $(uname -r)"
}

print_secure_boot_state() {
  section "Secure Boot"

  if command -v mokutil >/dev/null 2>&1; then
    mokutil --sb-state 2>/dev/null | sed 's/^/[INFO] /' || warn "mokutil could not read Secure Boot state"
  else
    warn "mokutil not found; cannot report Secure Boot state"
  fi

  info "Secure Boot can block unsigned NVIDIA kernel modules."
  info "Ubuntu's ubuntu-drivers path prefers pre-built signed modules when available."
}

print_display_adapters() {
  section "Display Adapters"

  if command -v lspci >/dev/null 2>&1; then
    if lspci | grep -Eiq 'vga|3d|display'; then
      lspci | grep -Ei 'vga|3d|display' | sed 's/^/[INFO] /'
    else
      warn "No display adapters found by lspci"
    fi
  else
    warn "lspci not found; install pciutils for PCI GPU inventory"
  fi
}

print_loaded_modules() {
  local modules

  section "GPU Kernel Modules"

  if command -v lsmod >/dev/null 2>&1; then
    modules="$(lsmod | grep -E '(^nvidia|^i915|^nouveau)' || true)"
    if [[ -n "${modules}" ]]; then
      printf "%s\n" "${modules}" | sed 's/^/[INFO] /'
    else
      warn "No nvidia, i915, or nouveau modules reported by lsmod"
    fi
  else
    warn "lsmod not found; cannot inspect loaded kernel modules"
  fi
}

print_installed_nvidia_packages() {
  local packages

  section "Installed NVIDIA Packages"

  if command -v dpkg-query >/dev/null 2>&1; then
    packages="$(
      dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package} ${Version}\n' \
        'nvidia-*' 'libnvidia-*' 'linux-modules-nvidia-*' 2>/dev/null \
        | awk '$1 ~ /^ii/ {print $2, $3}' \
        | sort -u || true
    )"
    if [[ -n "${packages}" ]]; then
      printf "%s\n" "${packages}" | sed 's/^/[INFO] /'
    else
      warn "No installed NVIDIA packages found by dpkg-query"
    fi
  else
    warn "dpkg-query not found; cannot inspect installed packages"
  fi
}

check_nvidia_device_nodes() {
  if compgen -G '/dev/nvidia*' >/dev/null; then
    ok "NVIDIA device nodes are visible"
    ls -l /dev/nvidia* | sed 's/^/[INFO] /'
    return 0
  fi

  warn "No /dev/nvidia* device nodes visible"
  return 1
}

check_dri_device_nodes() {
  if [[ -d /dev/dri ]]; then
    ok "/dev/dri is visible"
    ls -l /dev/dri | sed 's/^/[INFO] /'
    return 0
  fi

  warn "/dev/dri is not visible"
  return 1
}

check_nvidia_smi() {
  local output

  if command -v nvidia-smi >/dev/null 2>&1; then
    if output="$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>&1)"; then
      printf "%s\n" "${output}" | sed 's/^/[INFO] NVIDIA GPU: /'
      ok "nvidia-smi can communicate with the NVIDIA driver"
      return 0
    fi

    warn "nvidia-smi exists but cannot communicate with the NVIDIA driver"
    printf "%s\n" "${output}" | sed 's/^/[WARN] nvidia-smi output: /'
    return 1
  fi

  warn "nvidia-smi not found"
  return 1
}

print_proc_driver_version() {
  section "NVIDIA Driver Version File"

  if [[ -r /proc/driver/nvidia/version ]]; then
    sed 's/^/[INFO] /' /proc/driver/nvidia/version
  else
    warn "/proc/driver/nvidia/version is not readable"
  fi
}

print_cuda_tooling_state() {
  section "CUDA Toolkit Tooling"

  if command -v nvcc >/dev/null 2>&1; then
    ok "nvcc is available"
    nvcc --version | sed 's/^/[INFO] /'
  else
    warn "nvcc not found; CUDA Toolkit development tools are not in PATH"
  fi
}

print_docker_state() {
  section "Docker GPU State"

  if command -v docker >/dev/null 2>&1; then
    ok "docker is available at $(command -v docker)"
    docker --version 2>/dev/null | sed 's/^/[INFO] /' || true
    if docker info >/dev/null 2>&1; then
      ok "Docker daemon is reachable"
    else
      warn "Docker command exists but the daemon is not reachable for this user"
    fi
  else
    warn "docker not found; Docker GPU validation cannot run"
  fi

  if command -v nvidia-ctk >/dev/null 2>&1; then
    ok "nvidia-ctk is available at $(command -v nvidia-ctk)"
    nvidia-ctk --version 2>/dev/null | sed 's/^/[INFO] /' || true
  else
    warn "nvidia-ctk not found; NVIDIA Container Toolkit is not installed"
  fi
}

list_drivers() {
  section "Ubuntu Driver Discovery"

  if ! command -v ubuntu-drivers >/dev/null 2>&1; then
    warn "ubuntu-drivers not found; install ubuntu-drivers-common to list or install drivers"
    return 1
  fi

  echo "==> ubuntu-drivers devices"
  ubuntu-drivers devices || warn "ubuntu-drivers devices failed"

  echo
  echo "==> ubuntu-drivers list"
  ubuntu-drivers list || warn "ubuntu-drivers list failed"

  echo
  echo "==> ubuntu-drivers list --gpgpu"
  ubuntu-drivers list --gpgpu || warn "ubuntu-drivers list --gpgpu failed"
}

diagnose() {
  echo "==> NVIDIA GPU runtime diagnosis | START"
  echo "This mode is read-only: it does not call sudo, install packages, edit files, or run Docker containers."

  print_os_and_kernel
  print_display_adapters
  print_loaded_modules
  print_installed_nvidia_packages

  section "Device Nodes"
  check_nvidia_device_nodes || true
  check_dri_device_nodes || true

  section "nvidia-smi"
  check_nvidia_smi || true
  print_proc_driver_version
  print_secure_boot_state
  print_cuda_tooling_state
  print_docker_state
  list_drivers || true

  section "Interpretation"
  info "Fix host NVIDIA driver/runtime access before installing CUDA Toolkit or Python GPU libraries."
  info "CUDA Toolkit is only needed for CUDA development tools such as nvcc."
  info "Docker GPU workloads additionally require NVIDIA Container Toolkit and docker run --gpus."

  if [[ "${WARNINGS}" -eq 0 ]]; then
    ok "Diagnosis completed without warnings"
  else
    info "Diagnosis completed with ${WARNINGS} warning(s)"
  fi

  echo "==> NVIDIA GPU runtime diagnosis | END"
}

normalize_driver_branch() {
  local branch="$1"

  branch="${branch#nvidia-driver-}"
  branch="${branch#nvidia:}"

  if [[ ! "${branch}" =~ ^[0-9]+(-server)?(-open)?$ && ! "${branch}" =~ ^[0-9]+-open$ ]]; then
    die "driver branch must look like 550, 550-open, 550-server, or 550-server-open"
  fi

  printf "%s" "${branch}"
}

validate_driver_profile() {
  case "${NVIDIA_DRIVER_PROFILE}" in
    desktop|gpgpu)
      ;;
    *)
      die "NVIDIA_DRIVER_PROFILE must be desktop or gpgpu"
      ;;
  esac
}

install_driver() {
  local branch="${1:-}"
  local kernel_release
  local install_args=()

  validate_driver_profile
  kernel_release="$(uname -r)"

  echo "==> NVIDIA driver install | START"
  echo "This mode changes system packages and may require a reboot before graphics or GPU compute works."
  echo "Driver profile: ${NVIDIA_DRIVER_PROFILE}"

  sudo apt update
  run_full_upgrade
  sudo apt -y install ubuntu-drivers-common pciutils mokutil "linux-headers-${kernel_release}"

  list_drivers || true

  if [[ "${NVIDIA_DRIVER_PROFILE}" == "gpgpu" ]]; then
    install_args+=(--gpgpu)
  fi

  if [[ -n "${branch}" ]]; then
    branch="$(normalize_driver_branch "${branch}")"
    install_args+=("nvidia:${branch}")
    echo "==> Install selected NVIDIA driver branch: ${branch}"
  else
    echo "==> Install Ubuntu-recommended NVIDIA driver"
  fi

  sudo ubuntu-drivers install "${install_args[@]}"

  echo "==> NVIDIA driver install | END"
  echo "REBOOT REQUIRED: reboot before running verify-driver."
  echo "After reboot, run: ./nvidia_gpu_runtime_setup.sh verify-driver"
}

verify_driver() {
  local failures=0

  echo "==> NVIDIA driver verification | START"
  print_os_and_kernel
  print_loaded_modules

  section "Device Nodes"
  check_nvidia_device_nodes || failures=$((failures + 1))
  check_dri_device_nodes || failures=$((failures + 1))

  section "nvidia-smi"
  check_nvidia_smi || failures=$((failures + 1))
  print_proc_driver_version
  print_secure_boot_state

  if [[ "${failures}" -gt 0 ]]; then
    echo "==> NVIDIA driver verification | FAILED"
    echo "Reboot after driver changes, check Secure Boot/module signing, and rerun diagnose."
    exit 1
  fi

  ok "NVIDIA driver runtime is usable"
  echo "==> NVIDIA driver verification | END"
}

install_container_toolkit() {
  echo "==> NVIDIA Container Toolkit install | START"
  echo "This mode configures an APT repository, installs packages, updates Docker runtime config, and restarts Docker."

  require_command docker "Install Docker first, for example with development_setup.sh."
  require_command curl "Install curl before configuring the NVIDIA Container Toolkit repository."
  require_command gpg "Install gnupg before configuring the NVIDIA Container Toolkit repository."

  if ! check_nvidia_smi; then
    die "host NVIDIA driver is not usable yet; run install-driver, reboot, and verify-driver first"
  fi

  sudo apt update
  sudo apt -y install ca-certificates curl gnupg

  sudo install -m 0755 -d /usr/share/keyrings
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

  sudo apt update
  sudo apt -y install nvidia-container-toolkit

  sudo nvidia-ctk runtime configure --runtime=docker

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart docker
  else
    sudo service docker restart
  fi

  echo "==> NVIDIA Container Toolkit install | END"
  echo "Run: ./nvidia_gpu_runtime_setup.sh verify-docker-gpu"
}

verify_docker_gpu() {
  local image_existed=0

  echo "==> Docker GPU verification | START"
  echo "Test image: ${DOCKER_GPU_TEST_IMAGE}"

  require_command docker "Install Docker first, for example with development_setup.sh."

  if ! check_nvidia_smi; then
    die "host NVIDIA driver is not usable yet; run verify-driver first"
  fi

  if docker image inspect "${DOCKER_GPU_TEST_IMAGE}" >/dev/null 2>&1; then
    image_existed=1
  fi

  docker run --rm --gpus all "${DOCKER_GPU_TEST_IMAGE}" nvidia-smi

  if [[ "${image_existed}" == "0" && "${KEEP_DOCKER_GPU_TEST_IMAGE}" != "1" ]]; then
    echo "==> Remove temporary Docker GPU test image"
    docker rmi "${DOCKER_GPU_TEST_IMAGE}" || warn "could not remove ${DOCKER_GPU_TEST_IMAGE}; remove it manually if it was created only for this validation"
  else
    echo "==> Keeping Docker GPU test image (${DOCKER_GPU_TEST_IMAGE})"
  fi

  echo "==> Docker GPU verification | END"
}

print_cuda_guidance() {
  cat <<'GUIDANCE'
CUDA Toolkit guidance

- Fix and verify the host NVIDIA driver/runtime first.
- CUDA Toolkit is separate from the driver runtime.
- Install CUDA Toolkit only when you need development tools such as nvcc, CUDA headers, samples, or native CUDA compilation.
- Many Python GPU packages provide CUDA runtime dependencies through project package managers and do not require a global CUDA Toolkit.
- Keep torch, cupy, numba, tensorflow, dask, and similar Python GPU libraries inside project virtual environments.
- If CUDA Toolkit is needed, follow NVIDIA's current CUDA Installation Guide for Linux:
  https://docs.nvidia.com/cuda/cuda-installation-guide-linux/

Suggested project-level pattern:

  python3 -m venv .venv
  source .venv/bin/activate
  python -m pip install -U pip
  # Then install the GPU packages required by that project.

After any driver or CUDA package change, reboot when the installer or driver state indicates it is required, then rerun:

  ./nvidia_gpu_runtime_setup.sh verify-driver
GUIDANCE
}

main() {
  local mode="${1:-}"

  case "${mode}" in
    -h|--help|help)
      usage
      ;;
    diagnose)
      [[ $# -eq 1 ]] || die "diagnose does not accept extra arguments"
      diagnose
      ;;
    list-drivers)
      [[ $# -eq 1 ]] || die "list-drivers does not accept extra arguments"
      list_drivers
      ;;
    install-driver)
      [[ $# -le 2 ]] || die "install-driver accepts at most one driver branch argument"
      install_driver "${2:-}"
      ;;
    verify-driver)
      [[ $# -eq 1 ]] || die "verify-driver does not accept extra arguments"
      verify_driver
      ;;
    install-container-toolkit)
      [[ $# -eq 1 ]] || die "install-container-toolkit does not accept extra arguments"
      install_container_toolkit
      ;;
    verify-docker-gpu)
      [[ $# -eq 1 ]] || die "verify-docker-gpu does not accept extra arguments"
      verify_docker_gpu
      ;;
    print-cuda-guidance)
      [[ $# -eq 1 ]] || die "print-cuda-guidance does not accept extra arguments"
      print_cuda_guidance
      ;;
    "")
      usage >&2
      die "select an explicit mode"
      ;;
    *)
      usage >&2
      die "unknown mode: ${mode}"
      ;;
  esac
}

main "$@"
