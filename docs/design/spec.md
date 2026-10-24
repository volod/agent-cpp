# agent-cpp Specification

## Purpose

`agent-cpp` is a copy-ready template for C++20 command-line and device projects that people and
coding agents develop together. A fresh copy builds, tests and plans on day one: it ships an
`agent-cpp` command, one set of agent rules, quality gates shared by local work and CI, builds
for an amd64 host, Raspberry Pi 5 and Luckfox Pico from one source tree, and a planning
workflow in which every change traces from a specified capability to tests and current-state
documentation.

This specification is living. Behavior, boundaries and evaluation belong here, in capability
sections below or in capability pages copied from the [page template](template.md). Remaining
work belongs in the [plan](../impl/plan.md); delivered behavior in
[current state](../impl/current.md); modules and their edges in the
[architecture](architecture.md); choices that constrain future work in
[decision records](adr/README.md). A need discovered during implementation enters here first,
through [capability changes](../guide/planning-workflow.md#capability-changes).

## Scope

In scope:

- a CMake project with presets, one executable and module libraries under `src/`, built with
  Ninja;
- native amd64 builds and cross builds for the [targets](#targets), with tests run under
  qemu-user;
- release archives with checksums, published to GitHub Releases from a version tag;
- `make` commands that run plain `cmake`, `ctest`, `clang-format`, `clang-tidy` and `shellcheck`
  steps and are shared by local work and CI;
- gates for formatting, warnings as errors, sanitizers, static analysis, tests and planning
  integrity;
- `AGENTS.md` as the only rule source, with adapters for Claude, Gemini and Cursor;
- a capability registry, forward plan, task records, decision records and current-state pages.

Out of scope until a specified capability needs them: a business domain, threads,
configuration files, persistence, network services, CUDA code (the build supports it; no module
uses it), package-manager publishing (apt, Conan, vcpkg), code signing and deployment to
devices.

## Design principles

1. **Standard library first.** Every third-party library is justified in the
   [dependency table](#dependencies).
2. **Thin edges.** `main` wires the process, `cli` owns the command-line contract, and modules
   return `Status` values to it.
3. **One workflow.** `make` runs plain commands; CI runs the same `make` commands.
4. **One source, many targets.** Target differences live in toolchain files and presets, not in
   product code; code is written for 32-bit and 64-bit Arm as well as amd64.
5. **Deterministic evidence.** Tests are network-free and repeatable; acceptance is proven by
   commands another contributor can rerun, on every target the task names.
6. **Traceable work.** Specification, plan, record and current-state page agree, and
   `make lint-spec-plan` checks it.

## Cross-cutting rules

### Toolchain and build

- C++20 without compiler extensions. Floors: GCC 13, Clang 18, CMake 3.28 (the Ubuntu 24.04
  packages). Ubuntu 26.04 (GCC 15, Clang 21, CMake 4.2) is supported as well.
  `cmake/AgentToolchainChecks.cmake` fails configuration below the floor.
- Code follows the Google C++ Style Guide, formatted by `.clang-format` (Google, C++20) and
  checked by `.clang-tidy`; first-party code compiles with `-Wall -Wextra -Wpedantic`,
  conversion and shadowing warnings, and `-Werror` in every preset.
- No exceptions are thrown or caught; errors are values ([ADR 0001](adr/0001-errors-as-values.md)).
- C++20 modules are not used; `CMAKE_CXX_SCAN_FOR_MODULES` is off.
- The version is `project(... VERSION x.y.z)` in `CMakeLists.txt`; `agent-cpp version` and the
  archive names come from it. Releases are Git tags `vMAJOR.MINOR.PATCH` that must equal it.
- Parallel builds stay inside the [build budget](adr/0003-build-budget.md):
  `cmake/AgentBuildBudget.cmake` is the single source for compile, link and heavy job pools.

### Targets

| Target id | Hardware | CPU and ABI | Compiler (Ubuntu package) | Tests run under |
| --- | --- | --- | --- | --- |
| `linux-amd64` | x86_64 PC or server | x86-64, glibc | `g++` | host |
| `rpi5` | Raspberry Pi 5 | Cortex-A76, aarch64 | `g++-aarch64-linux-gnu` | `qemu-aarch64` |
| `luckfox-pico` | Luckfox Pico (RV1103 / RV1106) | Cortex-A7, armv7 hard-float, NEON | `g++-arm-linux-gnueabihf` | `qemu-arm` |

Cross-target executables are linked statically so one binary runs on any root file system of
its architecture, including the Luckfox uclibc Buildroot image
([ADR 0002](adr/0002-static-device-binaries.md)). Adding a target is a specification change:
a row here, a toolchain file, presets and an entry in the target table of `make/config.mk`.

### Dependencies

The product has no runtime dependency beyond the C++ standard library. Repository commands need
only GNU Make, CMake and POSIX shell tools.

| Dependency | Kind | Use |
| --- | --- | --- |
| [GoogleTest](https://github.com/google/googletest) 1.17.0 | test | Unit tests and matchers; built from a SHA-256-pinned release archive for every target so cross builds never use a host package |

Adding a row is a specification change: name the need, the standard-library alternative that
was rejected and why, the pin (version and hash), and whether it is light (FetchContent) or
heavy (cached prebuilt prefix; see [AGENTS.md](../../AGENTS.md#heavy-compilation-ninja--cmake--cuda)).

### Command-line contract

- Synopsis: `agent-cpp <command> [arguments]`. Commands: `version` (also `--version`) and `help`
  (also `-h`, `--help`).
- `version` prints one line:
  `agent-cpp <version> (<repository>, <os>/<arch>, <target>, <compiler> <compiler-version>)`.
- stdout carries command results and requested help only; usage errors and diagnostics go to
  stderr, prefixed with `agent-cpp: `.
- Exit codes: `0` success, `1` failure (including a failed write to stdout), `2` usage error.
  SIGINT and SIGTERM keep the default disposition; a capability that must clean up on
  interruption specifies its own handling.

## Project foundation

The repository builds, tests and checks itself from a fresh clone on Ubuntu 24.04 or 26.04
after `tools/setup-ubuntu.sh`. `make ci` runs every required gate: format check, shellcheck, the
`host-debug` and `host-asan` presets (build and tests), clang-tidy, the tooling's own tests,
`lint-spec-plan` and `lint-doc-links`. GitHub Actions runs the same command on both Ubuntu
releases.

Boundary: the foundation owns layout, tooling, gates and the agent workflow, not product
behavior.

Evaluation: `make ci` passes on a fresh clone in a clean Ubuntu 24.04 and 26.04 container
(`make matrix`); the tooling tests reproduce each planning defect the lint detects; the
black-box tests drive the built binary through its exit codes and streams. A negative result
names the failing gate and never weakens it.

## Multi-target build

One source tree builds for every [target](#targets). `make cross [TARGET=T]` configures
the target's debug preset with its toolchain file, builds, and runs the unit and black-box
tests under qemu-user. Without qemu the tests are still built, so they can be copied to a
device, but not registered with CTest. Toolchain files accept `AGENT_CROSS_PREFIX`,
`AGENT_CROSS_SYSROOT` and `AGENT_CROSS_GCC_VERSION` for vendor or versioned compilers that meet
the floor.

Boundary: building and emulated testing only. Flashing, deploying and running on real boards
are human-assisted; vendor SDK toolchains below GCC 13 (the Luckfox SDK's GCC 8) are not
supported.

Evaluation: `make cross` passes for `rpi5` and `luckfox-pico` in CI; `file` reports static
executables of the right architecture; the black-box version test checks the target name. The
capability is complete when the binaries are confirmed on real hardware. A negative result
names the target, the missing tool or the failing test.

## Release distribution

`make dist [TARGET=T] [TAG=vX.Y.Z]` builds the target's release preset (`linux-amd64` by
default) and writes `dist/agent-cpp-<version>-<target>.tar.gz` holding
`agent-cpp-<version>-<target>/bin/agent-cpp`, stripped and statically linked, and
`share/doc/agent-cpp/README.md` and `LICENSE`. Entries are sorted with fixed owners and
`SOURCE_DATE_EPOCH` timestamps. `TAG` fails before building unless it is `v` followed by the
project version.

Pushing a tag `vMAJOR.MINOR.PATCH` publishes a GitHub release: the release workflow runs
`make ci` and `make cross`, builds archives for every target with `TAG`, writes and
verifies `SHA256SUMS` and uploads everything with generated notes.

Boundary: no signing, SBOM, installers or package-manager publishing, and no byte-for-byte
reproducible binaries.

Evaluation: tooling tests cover the tag check and unknown targets; CI runs `make dist` for
every target on each push and keeps the archives. A negative result keeps the previous
release and names the failing target or the mismatched tag.

## Project identity

`agent-cpp version` names the command, version, repository, platform, target and compiler.
After a repository is created from the template, its project name, executable, C++ namespace,
CMake prefixes, repository URL, README and this specification name and describe the new
product.

Boundary: identity only. It does not choose the product's domain, libraries or architecture.

Evaluation: unit and black-box tests agree on the identity; no template name remains where it
denotes the active project; `make ci` passes. A negative result names the missing owner input
(product name, repository URL, description) instead of inventing it.

## Capability Registry

Every capability appears exactly once. Status is `planned` while it has open plan tasks and
`shipped` once its current-state page exists and no task remains. Row order is the
implementation line the plan follows.

| # | Capability | Status | How it is evaluated | Implementation |
| --- | --- | --- | --- | --- |
| 1 | `project-foundation` | shipped | `make ci` on a fresh clone in Ubuntu 24.04 and 26.04; tooling and black-box tests | [Current](../impl/current/project-foundation.md) |
| 2 | `multi-target-build` | planned | `make cross` for every target; confirmation on real boards | [Current](../impl/current/multi-target-build.md), [open work](../impl/plan.md#hardware-smoke-test) |
| 3 | `release-distribution` | shipped | Tooling tests; `make dist` for every target in CI; checksums verified before publishing | [Current](../impl/current/release-distribution.md) |
| 4 | `project-identity` | planned | Identity tests pass and no stale template identity remains after personalization | [Open work](../impl/plan.md#personalize-template-project) |

## Development integrity

[AGENTS.md](../../AGENTS.md) defines the task cycle; the
[planning workflow](../guide/planning-workflow.md) defines task shape, lanes, records and
checkpoints.

- Task records under `docs/impl/records/` keep the full accepted task, amendments, decisions and
  evidence per target. Current pages describe available behavior and link records. The plan
  holds only unresolved work.
- Decision records under `docs/design/adr/` keep choices that constrain later work; a task that
  makes or reverses one links it.
- Tests are deterministic, network-free and build fixtures in temporary directories; see the
  [test layout](../guide/development.md#test-layout).
- Coverage percentages are diagnostic, never a gate.
- Tests that need real hardware, credentials or human judgment are human-assisted or declared
  runs, never part of `make ci`.

## Success criteria

A team creates a repository from the template, completes the first plan task to give it its own
identity, and then adds capabilities by specifying them here, planning tasks, and closing each
task with a record and a current-state page, while `make ci` and `make cross` stay green.
A contributor can tell what the product promises, what remains, what exists, which targets it
runs on and how each capability is proven from the repository alone.
