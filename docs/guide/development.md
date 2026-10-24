# Development Guide

## Requirements

Ubuntu 24.04 or 26.04 on x86_64, prepared once with `tools/setup-ubuntu.sh` before any
development. It installs the whole toolchain system-wide with apt, ccache and the cross
compilers included. Build and gate commands (`check`, `ci`, `cross`, `run`, `dist`, `format`,
`tidy`, `jobs`) refuse to run until every tool it installs is present, so every development
system builds the same way and rebuilds stay cached; `make doctor` reports what is present.

| Tool | Floor (Ubuntu 24.04) | Ubuntu 26.04 | Needed for |
| --- | --- | --- | --- |
| GCC (`g++`), GNU Make | 13.2, 4.3 | 15.2, 4.4 | every build and command |
| CMake | 3.28 | 4.2 | every build |
| Ninja | 1.11 | 1.13 | every build (presets use it) |
| clang-format, clang-tidy | 18 | 21 | `make ci` |
| shellcheck | 0.9 | 0.11 | `make ci` (`lint-shell`) |
| `g++-aarch64-linux-gnu`, `g++-arm-linux-gnueabihf` | 13.2 | 15.2 | `make cross` |
| `qemu-user` | 8.2 | 10.2 | cross tests |
| Clang (`clang++`) | 18 | 21 | `host-clang` preset |
| ccache | 4.9 | 4.12 | cached rebuilds (`.cache/ccache`) |
| Docker | any | any | optional, `make matrix` |
| CUDA toolkit (`nvcc`) | 12.0 | 12.x / 13.x | optional, `host-cuda` preset |

`git`, `awk` and `sh` come with Ubuntu. Prepare the system with one command; it asks for sudo:

```bash
tools/setup-ubuntu.sh   # everything above except Docker and CUDA
make doctor             # versions against the floors and the build budget
```

Rerun it (or `make setup`) after pulling a change to the script; `make` names the missing tools
otherwise. Network access is needed
once per preset, to download the pinned GoogleTest archive into `.cache/fetchcontent/`.
Offline, pass `-DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=<unpacked dir>`.

## First run

```bash
make check                               # host-debug: configure, build, unit + black-box tests
./build/host-debug/src/agent-cpp version # agent-cpp 0.1.0 (https://github.com/volod/agent-cpp, linux/x86_64, host, gcc 15.2.0)
make ci                                  # every required gate
make cross                               # rpi5 and luckfox-pico under qemu-user
make plan-status                         # the next eligible task
```

Builds and tests run on the host: every command above calls the installed toolchain directly,
with no container. Only `make matrix` uses containers: it builds a clean Ubuntu 24.04 and 26.04
image and runs `make ci cross` in each, as CI does (`UBUNTU=26.04` picks one release). Its
build trees go under `build/ubuntu-<version>/`, so they never mix with host builds.

## Commands

The top-level `Makefile` is the only entry point; `make help` lists its commands by section. It includes one fragment per concern under `make/`:
`config.mk` (project identity from `project()`, variables, the target table), `build.mk`,
`dist.mk`, `quality.mk` (gates and planning) and `env.mk` (toolchain, budget, containers);
`help.awk` prints the help. Every recipe line is echoed as a plain command before it runs, so
any failure can be rerun by hand. Variables are passed as `make <command> NAME=value`.

| Command | Runs | Purpose |
| --- | --- | --- |
| `make check [PRESET=P]` | `cmake --preset P -DAGENT_BUILD_TESTS=ON`; `cmake --build --preset P`; `ctest --preset P` | Inner loop; default `host-debug` |
| `make ci` | `format-check`; `lint-shell`; `check` for `host-debug` and `host-asan`; `tidy`; `tools-test`; `lint-spec-plan`; `lint-doc-links` | Required before accepting a task; CI runs it |
| `make cross [TARGET=T]` | `check` with each cross target's debug preset | Declared run for tasks whose `Targets` name a device |
| `make run [ARGS='...']` | `cmake --build --preset host-debug --target agent-cpp`; the binary with `ARGS` | Try the command; default `version` |
| `make clean` | `rm -rf build dist .cache/fetchcontent` | Reset build trees and archives |
| `make format` / `format-check` | `clang-format -i` / `clang-format --dry-run -Werror` on tracked `*.cc *.h *.cu *.cuh` | Google style |
| `make tidy [PRESET=P]` | `clang-tidy -p build/P` on `src/**/*.cc` | Static analysis and naming |
| `make lint-shell` | `shellcheck` on tracked `*.sh` | Shell scripts stay POSIX-clean |
| `make tools-test` | `sh tools/tests/run.sh` | Tests of the tooling itself |
| `make jobs` | `cmake -P cmake/AgentBuildBudget.cmake` | Build budget |
| `make doctor` | `sh tools/doctor.sh` | Environment report |
| `make setup` | `tools/setup-ubuntu.sh` | System-wide toolchain install |
| `make dist [TARGET=T] [TAG=vX.Y.Z]` | `cmake --preset <T>-release`; `cmake --build`; `cmake --install --strip`; `tar` | Release archive in `dist/` |
| `make matrix [UBUNTU=26.04] [CMD='...']` | `docker build` of `tools/docker/dev.Dockerfile` and `docker run`, per release | Multi-release build and tests; default: both releases, `make ci cross` |
| `make plan-status` | `sh tools/plan.sh status` | Open task counts and the next eligible task |
| `make lint-spec-plan` | `sh tools/plan.sh lint` | Registry, plan and records agree |
| `make lint-doc-links` | `sh tools/doc-links.sh` | Relative Markdown links and anchors resolve |
| `make task-start TASK=<id>` / `task-close TASK=<id>` | `sh tools/plan.sh start` / `close` | Record bookkeeping; see the [planning workflow](planning-workflow.md#durable-task-records) |

Plain CMake works too, budget included: `cmake --workflow --preset host-debug`.

## Presets

| Preset | Build | Notes |
| --- | --- | --- |
| `host-debug` | Debug | `-Werror`, `_GLIBCXX_ASSERTIONS`; the default |
| `host-asan` | Debug | AddressSanitizer and UndefinedBehaviorSanitizer; part of `ci` |
| `host-clang` | Debug | `clang++`; CI runs it to catch compiler-specific code |
| `host-cuda` | Debug | `AGENT_ENABLE_CUDA=ON`; needs `AGENT_CUDA_ARCHITECTURES` (see below) |
| `host-release` | Release | static, `_FORTIFY_SOURCE=3`; used by `make dist TARGET=linux-amd64` |
| `rpi5-debug`, `rpi5-release` | Debug / Release | aarch64 Cortex-A76, static; tests under `qemu-aarch64` |
| `luckfox-debug`, `luckfox-release` | Debug / Release | armv7 Cortex-A7 hard-float, static; tests under `qemu-arm` |

Build trees are `build/<preset>/`; `rm -rf build .cache/fetchcontent` resets everything.
`compile_commands.json` is written in each build tree for editors and clang-tidy.

## Build budget

`cmake/AgentBuildBudget.cmake` sizes three Ninja job pools whenever CMake configures, from free
memory, the CPU affinity mask and cgroup v2 limits
([ADR 0003](../design/adr/0003-build-budget.md)); `make jobs` prints the result:

| Pool | Peak memory per job | CPU share | Used by |
| --- | --- | --- | --- |
| `compile` | 2 GB | all usable cores | every ordinary translation unit |
| `link` | 4 GB | half | every link |
| `heavy` | 12 GB | half | targets declared `HEAVY` or `CUDA` |

`AGENT_MAX_JOBS=<n>` in the environment lowers every pool, for example on a shared runner.
CTest runs one test per CPU (`TEST_JOBS`); tests are small. Mark a target heavy where it is
declared:

```cmake
agent_cc_library(NAME solver SRCS solver.cc HDRS solver.h HEAVY)
```

## CUDA

CUDA is opt-in and host-only. A module that uses it declares its targets with `CUDA` inside
`if(AGENT_ENABLE_CUDA)` and exposes a plain C++ header, so other modules and cross targets never
include CUDA headers:

```bash
export AGENT_CUDA_ARCHITECTURES=89   # RTX 40xx; "native" only on a workstation; never "all"
export CUDAHOSTCXX=g++-13           # when nvcc does not support the default g++
make check PRESET=host-cuda
```

nvcc translation units compile in the `heavy` pool. Ubuntu's `nvidia-cuda-toolkit` 12.4 accepts
GCC up to 13; NVIDIA's own packages track newer compilers.

## Toolchain and dependencies

- Compiler floors are enforced by `cmake/AgentToolchainChecks.cmake`. To raise one, change it
  there, in the [specification](../design/spec.md#toolchain-and-build) and in this guide
  together, then fix what the new warnings report.
- A light dependency (headers or a few translation units) is added with `FetchContent_Declare`
  using a release `URL` and `URL_HASH SHA256=...`, in its own `cmake/Agent<Name>.cmake`, and listed
  in the [dependency table](../design/spec.md#dependencies). It must build for every target.
- A heavy dependency follows the
  [heavy compilation rule](../../AGENTS.md#heavy-compilation-ninja--cmake--cuda): distribution
  package, prebuilt archive, or a cached install prefix under `.cache/deps/`.
- Warnings live in `cmake/AgentCompilerOptions.cmake` and apply to first-party targets only.
  Silence one only at the narrowest scope, with a comment naming the reason.
- Repository scripts are POSIX `sh` with POSIX `awk`, so they run under `dash` and `mawk`; only
  `tools/setup-ubuntu.sh` uses bash. `shellcheck` must pass; `.shellcheckrc` disables only
  SC2016 (awk programs and Markdown backticks in single quotes), with that reason.

## Test layout

| Path | Purpose |
| --- | --- |
| `src/<module>/<name>_test.cc` | Unit tests beside the code, declared with `agent_cc_test`; label `unit` |
| `tests/CMakeLists.txt` | Black-box tests: each `agent_cli_test` runs the built binary once and checks its exit code, stdout and stderr (`tests/run_cli.cmake`); label `blackbox` |
| `tests/fixtures/` | Committed inputs and golden outputs. Add it with its first file |
| `tools/tests/*_test.sh` | Tooling tests on throwaway repositories and fixture `/proc` files; `tools/tests/lib.sh` holds `expect` and `assert` |

Rules:

- Tests are deterministic and network-free. Write temporary files under `testing::TempDir()`
  (C++) or the scratch directory from `lib.sh` (shell); never commit large or binary fixtures
  when a test can generate them.
- Cross builds run the same tests under qemu-user through `CMAKE_CROSSCOMPILING_EMULATOR`; test
  discovery happens when CTest runs (`DISCOVERY_MODE PRE_TEST`), so building never needs qemu.
- `ctest --preset P -L unit` or `-L blackbox` selects one kind; `-R <regex>` one test.
- A slow, GPU or hardware test gets its own label and is a declared run in the task, never part
  of `make ci`.

## Versioning and releases

Versions follow [Semantic Versioning](https://semver.org) (`0.y.z` before 1.0). The single
source is `VERSION` in the top-level `project()` call; `agent-cpp version`, `make/config.mk` and
archive names read it.

To release, bump the version, run `make ci` and `make cross`, merge, then tag that commit and
push the tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow rebuilds every target from a clean checkout of the tag, fails when the tag
and the version differ, and publishes the archives and `SHA256SUMS` as a GitHub release.
`make dist TARGET=<T>` builds the same archive locally.

## CI

`.github/workflows/ci.yml` runs, for pushes to `main` and pull requests, a matrix over
`ubuntu:24.04` and `ubuntu:26.04` containers: `tools/setup-ubuntu.sh --yes`, `make doctor`,
`make ci`, `make check PRESET=host-clang`, `make cross` and `make dist` for every target.
`.github/workflows/release.yml` runs on `v*.*.*` tags. Keep workflows thin wrappers over `make`
so local and CI results agree; `make matrix` reproduces the CI matrix locally and
`make matrix UBUNTU=26.04` one job of it.
