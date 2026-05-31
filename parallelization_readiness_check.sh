#!/usr/bin/env bash
set -euo pipefail

WARNINGS=0

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

print_command_version() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    ok "${command_name}: $(command -v "${command_name}")"
    "${command_name}" --version 2>/dev/null | head -n 1 || true
  else
    warn "${command_name} not found"
  fi
}

check_cpu_memory_storage() {
  section "CPU, Memory, Storage"

  if command -v nproc >/dev/null 2>&1; then
    info "Logical CPUs: $(nproc)"
  else
    warn "nproc not found; cannot report logical CPU count"
  fi

  if [[ -r /proc/cpuinfo ]]; then
    local cpu_model
    cpu_model="$(awk -F ': ' '/model name/ {print $2; exit}' /proc/cpuinfo)"
    if [[ -n "${cpu_model}" ]]; then
      info "CPU model: ${cpu_model}"
    fi
  fi

  if [[ -r /proc/meminfo ]]; then
    awk '/MemTotal/ {printf "[INFO] Memory total: %.1f GiB\n", $2 / 1048576}' /proc/meminfo
  else
    warn "/proc/meminfo not readable; cannot report memory"
  fi

  if command -v df >/dev/null 2>&1; then
    info "Disk space for current filesystem:"
    df -h . | sed 's/^/[INFO] /'
  else
    warn "df not found; cannot report disk space"
  fi
}

check_python_parallelism() {
  section "Python Parallelism"

  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not found; install Python before validating project-level parallelism"
    return
  fi

  info "Python: $(python3 --version 2>&1)"

  if python3 - <<'PY'
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor


def square(value):
    return value * value


with ThreadPoolExecutor(max_workers=2) as executor:
    thread_results = list(executor.map(square, [1, 2, 3]))

with ProcessPoolExecutor(max_workers=2) as executor:
    process_results = list(executor.map(square, [1, 2, 3]))

if thread_results != [1, 4, 9] or process_results != [1, 4, 9]:
    raise SystemExit("unexpected executor result")
PY
  then
    ok "Python thread and process executor smoke check passed"
  else
    warn "Python executor smoke check failed; inspect multiprocessing support before relying on parallel jobs"
  fi
}

check_python_packages() {
  section "Optional Python Packages"

  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not found; skipping optional package checks"
    return
  fi

  local package
  for package in dask xarray rasterio rioxarray torch cupy numba; do
    if python3 - "${package}" <<'PY'
import importlib.util
import sys

raise SystemExit(0 if importlib.util.find_spec(sys.argv[1]) else 1)
PY
    then
      ok "Python package available: ${package}"
    else
      warn "Python package not available: ${package}"
    fi
  done
}

check_gpu_runtime() {
  section "GPU Runtime"

  if command -v lspci >/dev/null 2>&1; then
    info "Display adapters from lspci:"
    lspci | grep -Ei 'vga|3d|display' | sed 's/^/[INFO] /' || warn "No display adapters found by lspci"
  else
    warn "lspci not found; install pciutils for PCI GPU inventory"
  fi

  if command -v lsmod >/dev/null 2>&1; then
    if lsmod | grep -Eq '(^nvidia|^i915)'; then
      info "Relevant loaded kernel modules:"
      lsmod | grep -E '(^nvidia|^i915)' | sed 's/^/[INFO] /'
    else
      warn "No nvidia or i915 kernel modules reported by lsmod"
    fi
  else
    warn "lsmod not found; cannot inspect loaded GPU modules"
  fi

  if compgen -G '/dev/nvidia*' >/dev/null; then
    ok "NVIDIA device nodes are visible"
    ls -l /dev/nvidia* | sed 's/^/[INFO] /'
  else
    warn "No /dev/nvidia* device nodes visible"
  fi

  if [[ -d /dev/dri ]]; then
    ok "/dev/dri is visible"
    ls -l /dev/dri | sed 's/^/[INFO] /'
  else
    warn "/dev/dri is not visible"
  fi

  if command -v nvidia-smi >/dev/null 2>&1; then
    local nvidia_smi_output
    if nvidia_smi_output="$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>&1)"; then
      printf "%s\n" "${nvidia_smi_output}" | sed 's/^/[INFO] NVIDIA GPU: /'
      ok "nvidia-smi can communicate with the NVIDIA driver"
    else
      warn "nvidia-smi exists but cannot communicate with the NVIDIA driver"
      printf "%s\n" "${nvidia_smi_output}" | sed 's/^/[WARN] nvidia-smi output: /'
    fi
  else
    warn "nvidia-smi not found"
  fi

  if command -v nvcc >/dev/null 2>&1; then
    ok "nvcc is available"
    nvcc --version | sed 's/^/[INFO] /'
  else
    warn "nvcc not found; CUDA toolkit is not available in PATH"
  fi
}

check_containers() {
  section "Container Tooling"

  if command -v docker >/dev/null 2>&1; then
    ok "docker: $(command -v docker)"
    docker --version 2>/dev/null | sed 's/^/[INFO] /' || true
  else
    warn "docker not found; Docker smoke validation cannot run on this machine"
  fi
}

main() {
  echo "==> Parallelization and GPU readiness check | START"
  echo "This script is read-only: it does not call sudo, install packages, or edit files."

  check_cpu_memory_storage
  check_python_parallelism
  check_python_packages
  check_gpu_runtime
  check_containers

  section "Interpretation"
  info "CPU thread/process parallelism can be useful even when GPU readiness is incomplete."
  info "GPU acceleration requires visible device nodes, a working driver runtime, and project-specific Python/GPU libraries."
  info "Network-bound workflows often benefit more from bounded CPU thread concurrency than from GPU acceleration."

  if [[ "${WARNINGS}" -eq 0 ]]; then
    ok "Readiness check completed without warnings"
  else
    warn "Readiness check completed with ${WARNINGS} warning(s)"
  fi

  echo "==> Parallelization and GPU readiness check | END"
}

main "$@"
