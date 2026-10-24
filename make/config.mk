# Shared variables: project identity, presets, the target table and file lists.

# Name and version from project() in CMakeLists.txt, the single version source.
IDENTITY := $(shell awk '/^project\(/ { p = 1 } p { s = s " " $$0 } p && /\)/ { exit } \
  END { gsub(/[()]/, " ", s); n = split(s, t, " "); \
        for (i = 1; i < n; i++) { if (t[i] == "project" && name == "") name = t[i + 1]; \
                                  if (t[i] == "VERSION" && version == "") version = t[i + 1] } \
        print name, version }' $(PROJECT_ROOT)/CMakeLists.txt)
APP     := $(word 1,$(IDENTITY))
VERSION := $(word 2,$(IDENTITY))

# Command variables: make <target> NAME=value.
PRESET ?= host-debug
TARGET ?=
TAG    ?=
TASK   ?=
ARGS   ?= version
# Ubuntu releases `make matrix` builds and tests in clean containers; UBUNTU=26.04 picks one.
UBUNTU_RELEASES := 24.04 26.04
UBUNTU ?= $(UBUNTU_RELEASES)
CMD    ?= make ci cross
SOURCE_DATE_EPOCH ?= 0
# Tests are small; CTest runs one per CPU. Build parallelism comes from the Ninja job pools
# that cmake/AgentBuildBudget.cmake sizes.
TEST_JOBS ?= $(shell nproc)
BUILD_ROOT := $(PROJECT_ROOT)/build/$(AGENT_BUILD_PREFIX)
DIST_DIR   := $(PROJECT_ROOT)/dist

# Target table (ids as in docs/design/spec.md#targets): preset prefix, compiler, test emulator.
TARGETS       := linux-amd64 rpi5 luckfox-pico
CROSS_TARGETS := rpi5 luckfox-pico
preset_linux-amd64  := host
preset_rpi5         := rpi5
preset_luckfox-pico := luckfox
cxx_linux-amd64     := g++
cxx_rpi5            := aarch64-linux-gnu-g++
cxx_luckfox-pico    := arm-linux-gnueabihf-g++
qemu_rpi5           := qemu-aarch64
qemu_luckfox-pico   := qemu-arm

# Tracked and new, not ignored, files that still exist.
tracked = $(wildcard $(shell git -C $(PROJECT_ROOT) ls-files --cached --others --exclude-standard -- $(1)))
CXX_FILES = $(call tracked,'*.cc' '*.h' '*.cu' '*.cuh')
SH_FILES  = $(call tracked,'*.sh')

# Build and gate commands depend on `ready`: the toolchain from tools/setup-ubuntu.sh is present.
.PHONY: ready
ready:
	@sh $(PROJECT_ROOT)/tools/doctor.sh --check
