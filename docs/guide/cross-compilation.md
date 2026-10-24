# Cross-Compilation Guide

One source tree builds for every [target](../design/spec.md#targets). Board differences live in
toolchain files under `cmake/toolchains/` and in presets; product code never tests for a board.
Decisions behind this layout: [ADR 0002](../design/adr/0002-static-device-binaries.md).

## Quick start

```bash
tools/setup-ubuntu.sh                  # includes the cross compilers and qemu-user
make cross                             # build and test rpi5 and luckfox-pico under qemu
make dist TARGET=rpi5                  # dist/agent-cpp-<version>-rpi5.tar.gz
scp dist/agent-cpp-*-rpi5.tar.gz pi@raspberrypi.local:
```

On the board: `tar xzf agent-cpp-*-rpi5.tar.gz && ./agent-cpp-*/bin/agent-cpp version`.

## Toolchains

| Target | Toolchain file | Compiler | CPU flags | Linking |
| --- | --- | --- | --- | --- |
| `linux-amd64` | none (host) | `g++` | x86-64 baseline | dynamic for debug, static for release |
| `rpi5` | `cmake/toolchains/rpi5.cmake` | `aarch64-linux-gnu-g++` | `-mcpu=cortex-a76` | static |
| `luckfox-pico` | `cmake/toolchains/luckfox-pico.cmake` | `arm-linux-gnueabihf-g++` | `-mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard -mthumb` | static |

Board files set the triple, the qemu program and the CPU flags, then include
`linux-gnu-cross.cmake`, which sets the compilers, find-root rules and
`CMAKE_CROSSCOMPILING_EMULATOR`. The compiler floor (GCC 13, Clang 18) applies to every
toolchain; configuration fails below it.

Overrides, as environment variables or `-D` options at configure time:

| Variable | Use |
| --- | --- |
| `AGENT_CROSS_GCC_VERSION` | Versioned distribution compiler, e.g. `14` selects `aarch64-linux-gnu-g++-14` |
| `AGENT_CROSS_PREFIX` | Full compiler prefix of another toolchain, e.g. `/opt/arm-gnu/bin/aarch64-none-linux-gnu-` |
| `AGENT_CROSS_SYSROOT` | Target sysroot for headers and libraries; also passed to qemu as `-L` |

## Boards

### Raspberry Pi 5

BCM2712 with four Cortex-A76 cores, 2-16 GB RAM, AArch64. The static binary runs on 64-bit
Raspberry Pi OS (Debian 12, glibc 2.36) and Ubuntu for Raspberry Pi. A 32-bit Raspberry Pi OS
userland needs the `luckfox-pico`-style armhf build with Cortex-A76 flags; add it as a separate
target if it is ever needed. Building natively on the Pi works with the `host-*` presets; the
[build budget](development.md#build-budget) keeps it to about two compile jobs on 8 GB.

### Luckfox Pico

Rockchip RV1103 (Pico, Pico Mini, Pico Plus: 64 MB DDR2) or RV1106 (Pico Pro, Pico Max, Pico
Ultra: 128-256 MB DDR3): a single Cortex-A7 at 1.2 GHz with NEON and VFPv4, plus an NPU and ISP
that this template does not use. The vendor Buildroot image uses uclibc and the vendor SDK
compiler is GCC 8.3 (`arm-rockchip830-linux-uclibcgnueabihf`), which is below the C++20 floor,
so the template uses Ubuntu's `arm-linux-gnueabihf` GCC and links statically; the result runs on
the Buildroot image and on Luckfox's Ubuntu image alike.

Memory is the binding constraint: keep resident memory per process in single-digit megabytes,
avoid large static buffers, and state the memory budget in any capability that runs on this
target. Using the NPU (RKNN runtime) or camera pipeline requires the vendor's shared libraries
and therefore dynamic linking against the SDK sysroot: that is a specification change that
supersedes ADR 0002 for this target.

## Testing

- `make cross` builds the debug preset of each target and runs the full CTest suite under
  qemu-user through `CMAKE_CROSSCOMPILING_EMULATOR`; static binaries need no target sysroot.
- Without qemu installed, cross configurations still build every test executable but register
  none; copy `build/<preset>/src/**/*_test` to a board and run them there.
- qemu-user emulates the instruction set, not the board: it does not catch timing, memory
  limits, kernel or driver differences. Behavior that depends on them needs a human-assisted
  run on hardware, recorded in the task record.

## Adding a target

1. Add a row to the [target table](../design/spec.md#targets) (a specification change) and,
   when its choices differ from existing targets, a decision record.
2. Add `cmake/toolchains/<board>.cmake` that sets the four `AGENT_CROSS_*` variables and includes
   `linux-gnu-cross.cmake`.
3. Add `<board>-debug` and `<board>-release` presets inheriting `base`, with `AGENT_STATIC`,
   `AGENT_TARGET_NAME` and the toolchain file; add the matching build and test presets.
4. Add the target to the target table in `make/config.mk` (`TARGETS`,
   `CROSS_TARGETS`, its preset prefix, compiler and emulator) and the packages to
   `tools/setup-ubuntu.sh`.
5. Run `make cross TARGET=<board>` and `make dist TARGET=<board>`, and add the target
   to the release matrix in `.github/workflows/release.yml`.
