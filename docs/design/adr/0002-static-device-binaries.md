# 0002: Distribution cross compilers and static device binaries

- Status: accepted
- Context links: [Targets](../spec.md#targets), [Multi-target build](../spec.md#multi-target-build),
  [cross-compilation guide](../../guide/cross-compilation.md).

## Context

Raspberry Pi OS (Debian 12) ships glibc 2.36; Ubuntu 26.04 builds against glibc 2.42, so a
dynamically linked binary built on the development host fails on the board with
`GLIBC_2.38 not found`. The Luckfox Pico Buildroot image uses uclibc, and the vendor SDK's
cross compiler is GCC 8, which lacks most of C++20 (`<format>`, `<span>` details, concepts in
the library).

## Decision

- Cross targets use the Ubuntu cross compilers (`g++-aarch64-linux-gnu`,
  `g++-arm-linux-gnueabihf`, GCC 13 or newer) with board CPU flags in a toolchain file.
- Cross-target executables, tests included, are linked fully statically (`AGENT_STATIC=ON`), so
  one binary runs on any root file system of its architecture: Raspberry Pi OS, Ubuntu,
  Buildroot with uclibc or musl.
- Tests run under qemu-user on the development host and in CI; real boards confirm releases.
- Vendor toolchains are allowed through `AGENT_CROSS_PREFIX` / `AGENT_CROSS_SYSROOT` only if they
  meet the compiler floor.

## Alternatives

- Dynamic linking against a board sysroot: correct libraries, but every target needs a
  maintained sysroot image and the binary is tied to one OS release.
- Vendor SDK toolchains: C++17 at best on Luckfox; rejected for a C++20 code base.
- musl cross toolchains: smaller static binaries, but not packaged by Ubuntu and no qemu
  integration out of the box.

## Consequences

Binaries are larger (the libstdc++ and glibc static archives, roughly 1-2 MB for this CLI) and
glibc's NSS-based functions (`getpwnam`, `getaddrinfo` with NSS modules) are unavailable or
limited in static binaries. A capability that needs them, or a library available only as a
shared object on the device (GPU, NPU, camera drivers), must specify dynamic linking against a
board sysroot for that target and supersede this record for it.
