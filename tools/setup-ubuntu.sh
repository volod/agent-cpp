#!/usr/bin/env bash
# Prepares a development system: installs the toolchain system-wide on Ubuntu 24.04 or 26.04
# with apt. Run it once before development; build and gate commands refuse to run until every
# tool it installs is present (tools/doctor.sh --check).
#
#   tools/setup-ubuntu.sh [--yes] [--dry-run]
#
#   installs   make, cmake, ninja, g++, ccache, clang-format, clang-tidy, shellcheck, git,
#              clang++, the rpi5 (aarch64) and luckfox-pico (armhf) cross compilers, qemu-user
#   --yes      do not ask before installing (CI, containers)
#   --dry-run  print the apt command and exit
#
# Runs apt through sudo unless already root. Other distributions: install the same tools with
# the versions listed in docs/guide/development.md#requirements.
set -euo pipefail

yes=0 dry=0
for arg in "$@"; do
  case "$arg" in
    --yes) yes=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "setup-ubuntu.sh: unknown option $arg" >&2; exit 2 ;;
  esac
done

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  case "${VERSION_ID:-}" in
    24.04|26.04) ;;
    *) echo "setup-ubuntu.sh: warning: tested on Ubuntu 24.04 and 26.04, found ${PRETTY_NAME:-unknown}" >&2 ;;
  esac
fi

packages=(build-essential cmake ninja-build git ccache clang-format clang-tidy shellcheck clang
  g++-aarch64-linux-gnu g++-arm-linux-gnueabihf qemu-user ca-certificates)

sudo=()
if (( EUID != 0 )); then
  sudo=(sudo)
fi
apt_flags=(--no-install-recommends)
if (( yes )); then
  apt_flags+=(-y)
fi

if (( dry )); then
  echo "${sudo[*]} apt-get install ${apt_flags[*]} ${packages[*]}"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
"${sudo[@]}" apt-get update
"${sudo[@]}" apt-get install "${apt_flags[@]}" "${packages[@]}"
echo "setup-ubuntu.sh: done; run make doctor"
