# agent-cpp

A copy-ready C++20 project skeleton for teams that want coding agents to work from one set of
rules, one product specification and one forward plan, and ship the same code to an amd64
host, a Raspberry Pi 5 and a Luckfox Pico.

A fresh copy builds an `agent-cpp` command for every target, passes its quality gates on
Ubuntu 24.04 and 26.04, and has a machine-checked plan whose first task gives the new
repository its own identity. The layout, gates and planning workflow are meant to stay; the
name and the product are yours.

## Quick start

Requirements: Ubuntu 24.04 or 26.04 (x86_64) and Git.

```bash
tools/setup-ubuntu.sh   # required once: system-wide apt install of make, GCC, CMake, Ninja, ccache, clang tools, cross compilers, qemu
make check              # host-debug: configure, build, unit and black-box tests
./build/host-debug/src/agent-cpp version
# agent-cpp 0.1.0 (https://github.com/volod/agent-cpp, linux/x86_64, host, gcc 15.2.0)
make ci                 # every required gate (what CI runs)
make cross              # Raspberry Pi 5 and Luckfox Pico builds, tests under qemu
make plan-status        # next agent task: personalize-template-project
```

## Start a project from the template

1. Create a repository from this template and clone it.
2. Ask your agent to take the next task from `make plan-status`. The first one,
   `personalize-template-project`, renames the project, executable, namespace and docs; give it
   the product name, repository URL, a one-line description and the code prefix you want.
3. Describe the product's first capability in the [specification](docs/design/spec.md), then
   plan and implement it as the [planning workflow](docs/guide/planning-workflow.md) describes.

## Targets

| Target | Hardware | Build | Tests |
| --- | --- | --- | --- |
| `linux-amd64` | x86_64 PC or server | native GCC or Clang | host |
| `rpi5` | Raspberry Pi 5 (Cortex-A76, aarch64) | `g++-aarch64-linux-gnu`, static | `qemu-aarch64` |
| `luckfox-pico` | Luckfox Pico RV1103 / RV1106 (Cortex-A7, armv7hf) | `g++-arm-linux-gnueabihf`, static | `qemu-arm` |

Static device binaries run on Raspberry Pi OS, Ubuntu and the Luckfox uclibc Buildroot image
alike. See the [cross-compilation guide](docs/guide/cross-compilation.md).

## Daily commands

| Command | Purpose |
| --- | --- |
| `make check [PRESET=P]` | Configure, build and test one preset (inner loop) |
| `make ci` | Required gate: format, shell lint, `-Werror` build, ASan/UBSan, clang-tidy, tooling tests, plan and link lints |
| `make cross [TARGET=T]` | Cross build and emulated tests for device targets |
| `make run ARGS=help` | Build host-debug and run the command |
| `make format` | Apply Google style with clang-format |
| `make jobs` | Parallel build budget from memory, CPUs and cgroup limits |
| `make dist [TARGET=T]` | Release archive into `dist/` |
| `make matrix [UBUNTU=26.04]` | Build and test on Ubuntu 24.04 and 26.04 in clean containers, as CI does |
| `make setup` / `make doctor` | Install the toolchain system-wide / report what is installed |
| `make plan-status` | Count open tasks and show the next eligible one |
| `make task-start TASK=<id>` / `task-close TASK=<id>` | Create a task record / retire an accepted task |
| `make help` | List every repository command |

The [development guide](docs/guide/development.md) lists the plain command behind each one.
CMake presets work without `make` too, build budget included:
`cmake --workflow --preset host-debug`.

## Releases

Set `VERSION` in the top-level `project()` call, merge, then push the matching tag; the release
workflow checks, builds static archives for every target and publishes them with
`SHA256SUMS`:

```bash
git tag v0.1.0 && git push origin v0.1.0
```

## How work flows

```text
docs/design/spec.md       what the product must do, on which targets, how each capability is evaluated
        |
docs/design/adr/          decisions every later task must respect
        |
docs/impl/plan.md         only work that remains, ordered by the capability registry
        |
docs/impl/records/        one record per task: full scope, decisions, evidence per target
        |
docs/impl/current.md      what exists now, linking the records that prove it
```

`make lint-spec-plan` fails when these documents disagree, and `make lint-doc-links`
fails on a broken relative link or anchor.

## Layout

```text
src/main.cc        process wiring: arguments, streams, exit code
src/cli/           command-line contract: commands, help, exit codes
src/build_info/    build identity: version, repository, platform, target, compiler
src/base/          Status and StatusOr: errors as values, no exceptions
tests/             black-box tests of the built binary
cmake/             target helpers, compiler options, build budget, toolchains per board
Makefile, make/    every repository command: gates, cross builds, release archives, planning
tools/             setup and doctor, planning and link checks (POSIX sh + awk) and their tests
docs/              specification, decisions, plan, records, current state, guides
```

## Agent support

[AGENTS.md](AGENTS.md) is the only rule file. `CLAUDE.md` and `GEMINI.md` import it, and the
Cursor rule in `.cursor/rules/` points to it; Codex and other agents read `AGENTS.md` directly.

## License

MIT. See [LICENSE](LICENSE).
