# Multi-Target Build

## Targets and toolchains

The [target table](../../design/spec.md#targets) lists `linux-amd64`, `rpi5` and
`luckfox-pico`. `cmake/toolchains/rpi5.cmake` (`aarch64-linux-gnu`, `-mcpu=cortex-a76`) and
`cmake/toolchains/luckfox-pico.cmake` (`arm-linux-gnueabihf`, `-mcpu=cortex-a7
-mfpu=neon-vfpv4 -mfloat-abi=hard -mthumb`) include `linux-gnu-cross.cmake`, which sets the
compilers, find-root rules, the qemu-user emulator and the `AGENT_CROSS_PREFIX`,
`AGENT_CROSS_SYSROOT` and `AGENT_CROSS_GCC_VERSION` overrides. The
[cross-compilation guide](../../guide/cross-compilation.md) describes the boards.

## Presets and commands

`rpi5-debug`, `rpi5-release`, `luckfox-debug` and `luckfox-release` set the toolchain file,
`AGENT_STATIC=ON` and `AGENT_TARGET_NAME`. `make cross [TARGET=T]` configures, builds and
runs CTest for each debug preset; tests run under `qemu-aarch64` or `qemu-arm` through
`CMAKE_CROSSCOMPILING_EMULATOR`, and are built but not registered when qemu is missing.
The target table in `make/config.mk` maps target ids to preset prefixes, compilers and emulators.

## Evidence and limits

Unit and black-box tests pass under qemu-user for both device targets on Ubuntu 24.04 and
26.04 hosts; `file` reports statically linked aarch64 and 32-bit ARM EABI5 executables. Real
hardware runs are the open human task
[`hardware-smoke-test`](../plan.md#hardware-smoke-test); until then, behavior on the boards
themselves (kernel, memory limits, uclibc userland) is unconfirmed.
