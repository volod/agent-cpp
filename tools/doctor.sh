#!/bin/sh
# Checks that this system has the toolchain tools/setup-ubuntu.sh installs.
#
#   tools/doctor.sh          report every tool with its version, then the build budget
#   tools/doctor.sh --check  print nothing when ready, else the missing tools
#
# Exit 1 when a required tool is missing; build and gate commands run `--check` first.
set -u
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
check=0
case ${1:-} in
  --check) check=1 ;;
  '') ;;
  *) echo "usage: tools/doctor.sh [--check]" >&2; exit 2 ;;
esac
missing=

# row <program> <required yes|no> <note>
row() {
  path=$(command -v "$1" 2>/dev/null) || path=
  if [ -z "$path" ]; then
    state=absent
    if [ "$2" = yes ]; then
      state=MISSING
      missing="$missing $1"
    fi
    [ "$check" -eq 1 ] || printf '%-28s %-8s %s\n' "$1" "$state" "$3"
    return
  fi
  [ "$check" -eq 0 ] || return 0
  case $1 in
    awk) version=$path ;;  # mawk and gawk disagree on the version flag.
    *)
      # The line that names a version or release, else the first line with a number.
      out=$("$path" --version 2>&1 </dev/null)
      version=$(printf '%s\n' "$out" | sed -n -e '/[Vv]ersion:\{0,1\} [0-9]/{p;q;}' -e '/release [0-9]/{p;q;}')
      [ -n "$version" ] || version=$(printf '%s\n' "$out" | sed -n '/[0-9]/{p;q;}')
      ;;
  esac
  printf '%-28s %-8s %s%s\n' "$1" ok "$version" "${3:+  ($3)}"
}

# Everything tools/setup-ubuntu.sh installs is required.
row cmake yes ">= 3.28"
row ninja yes ""
row g++ yes ">= 13"
row make yes ""
row awk yes ""
row git yes ""
row ccache yes "cached rebuilds"
row clang-format yes ">= 18"
row clang-tidy yes ">= 18"
row shellcheck yes "make lint-shell"
row clang++ yes ">= 18, preset host-clang"
row aarch64-linux-gnu-g++ yes "target rpi5"
row qemu-aarch64 yes "target rpi5 tests"
row arm-linux-gnueabihf-g++ yes "target luckfox-pico"
row qemu-arm yes "target luckfox-pico tests"
# Installed separately when a task needs them.
row docker no "make matrix"
row nvcc no "preset host-cuda"
if [ "$check" -eq 0 ] && command -v cmake >/dev/null 2>&1; then
  printf '%-28s %-8s %s\n' "build budget" "" "$(cmake -P "$root/cmake/AgentBuildBudget.cmake" 2>&1)"
fi
if [ -n "$missing" ]; then
  echo "doctor: missing:$missing" >&2
  echo "doctor: prepare this system once with tools/setup-ubuntu.sh (asks for sudo); make doctor reports it" >&2
  exit 1
fi
