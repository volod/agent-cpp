#!/bin/sh
# Tests of the Makefile's argument checks; each case stops before running any build command.
set -eu
# shellcheck source=lib.sh
. "$(dirname -- "$0")/lib.sh"

run_make() {
  make -s -C "$repo" "$@"
}

version=$(sed -n 's/^ *VERSION \([0-9][0-9.]*\)$/\1/p' "$repo/CMakeLists.txt")
project=$(sed -n '/^project($/{n;s/^ *//p;}' "$repo/CMakeLists.txt")

expect "help lists sections" 0 "Quality:" run_make help
expect "help lists commands" 0 "  check            Configure, build and test one preset" run_make help
# The description names "project" too; the archive must use the name after project(.
expect "dist: archive name from project()" 0 "dist/$project-$version-rpi5.tar.gz $project-$version-rpi5" \
  run_make -n dist TARGET=rpi5
expect "dist: tag must equal the version" 2 \
  "tag v0.0.0-bad does not match project version $version (want v$version)" \
  run_make dist TAG=v0.0.0-bad
expect "dist: unknown target" 2 'unknown target "pdp11"' run_make dist TARGET=pdp11
expect "cross: host is not a cross target" 2 'unknown cross target "linux-amd64"' \
  run_make cross TARGET=linux-amd64
expect "matrix: unknown release" 2 'unknown Ubuntu release "22.04"' run_make matrix UBUNTU=22.04
# A dry run names one image per release: both by default, one when UBUNTU names it.
expect "matrix: both releases by default" 0 "for u in 24.04 26.04; do" run_make -n matrix
expect "matrix: one named release" 0 "-dev:ubuntu-26.04" run_make -n matrix-one UBUNTU=26.04

# A system without the toolchain from tools/setup-ubuntu.sh is refused before anything runs.
bin=$scratch/bin
mkdir -p "$bin"
for program in sh awk dirname; do
  ln -s "$(command -v "$program")" "$bin/$program"
done
make_program=$(command -v make)
expect "ready: names the missing tools" 2 "doctor: missing: cmake ninja" \
  env PATH="$bin" "$make_program" -s -C "$repo" check
expect "ready: points at the setup script" 2 "prepare this system once with tools/setup-ubuntu.sh" \
  env PATH="$bin" "$make_program" -s -C "$repo" ci
expect "ready: planning needs no toolchain" 0 "open tasks:" \
  env PATH="$bin" "$make_program" -s -C "$repo" plan-status

finish
