# Project Foundation

## Layout and command

A CMake 3.28+ project (`CMakeLists.txt`, `CMakePresets.json`) in C++20 with the Ninja
generator; the [architecture](../../design/architecture.md) lists the tree and the dependency
direction.

- `src/main.cc` converts `argv` to `std::string_view`s and returns `cli::Run(args, std::cout,
  std::cerr)` as the exit code.
- `src/cli/` implements `version`, `--version`, `help`, `-h`, `--help`, usage errors with exit
  code `2` on stderr, and exit code `1` when stdout cannot be written, per the
  [command-line contract](../../design/spec.md#command-line-contract).
- `src/build_info/` reports name, version and repository from the CMake project, the target
  name from `AGENT_TARGET_NAME`, and OS, architecture and compiler from predefined macros.
- `src/base/` provides `Status`, `StatusOr<T>` and `AGENT_RETURN_IF_ERROR`
  ([ADR 0001](../../design/adr/0001-errors-as-values.md)).

## Build system

- `cmake/AgentTargets.cmake` declares every target (`agent_cc_library`, `agent_cc_binary`,
  `agent_cc_test`) with the warnings, hardening (`-fstack-protector-strong`,
  `_FORTIFY_SOURCE=3` outside Debug, `_GLIBCXX_ASSERTIONS` in Debug), sanitizers and static
  linking of `cmake/AgentCompilerOptions.cmake`.
- `cmake/AgentToolchainChecks.cmake` rejects GCC < 13 and Clang < 18.
- `cmake/AgentGoogleTest.cmake` fetches GoogleTest 1.17.0 by URL and SHA-256 into
  `.cache/fetchcontent/<preset>/` and registers tests at CTest time (`DISCOVERY_MODE PRE_TEST`).
- `cmake/AgentBuildBudget.cmake` sizes the `compile`, `link` and `heavy` Ninja job pools at
  configure time from `MemAvailable`, the CPU affinity mask and the cgroup v2 `memory.max` and
  `cpu.max` of the process's cgroup and its ancestors, capped by `AGENT_MAX_JOBS`; in script
  mode (`make jobs`) it prints them. It also enables ccache when installed
  ([ADR 0003](../../design/adr/0003-build-budget.md)).
- `cmake/AgentCuda.cmake` enables CUDA for the `host-cuda` preset, requires explicit
  architectures and rejects `all`; no module uses CUDA yet.

## Gates

The top-level `Makefile` holds every command, split by concern into `make/*.mk` and listed by
`make help`. `make ci` runs
`clang-format --dry-run -Werror` (Google style, `.clang-format`), `shellcheck` on the shell
scripts, the `host-debug` and `host-asan` presets (configure, build with `-Werror`, CTest),
`clang-tidy` with `.clang-tidy` (bugprone, google, modernize, performance, readability and
Google naming), the tooling tests, `lint-spec-plan` and `lint-doc-links`; each step is echoed as
a plain command. `make/config.mk` reads the project name and version from `project()` and holds
the target table (preset prefix, compiler and emulator per target). `tools/setup-ubuntu.sh` (or `make setup`) installs the whole
toolchain with apt; every build and gate command first runs `tools/doctor.sh --check` and stops,
naming the missing tools, until it is complete; `make doctor` reports tools against the floors; `make matrix` reruns the gates (or `CMD`) in clean
Ubuntu 24.04 and 26.04 containers built from `tools/docker/dev.Dockerfile`. The
[development guide](../../guide/development.md) lists every command.

## Planning tooling

`tools/plan.sh` (POSIX `sh` and `awk`) parses the capability registry and target table of the
specification, the plan and the task records into one model. `status` counts open tasks per
lane and lists the eligible ones. `lint` checks registry statuses, open-task counts and
current-page links; task ids, required fields and lane statuses; `Serves` capabilities;
dependencies on open tasks or existing records; known `Targets`; and records that are named
`NNNN-<task-id>.md`, uniquely sequenced, indexed, consistent with their first scope line and not
accepted while their task is open. `start` writes the numbered record with the verbatim task,
commit, dirty files, counts and targets, and indexes it; `close` removes an accepted task,
rewrites references to the record link, marks the index and reruns the lint.
`tools/doc-links.sh` checks relative links and GitHub anchors in every tracked Markdown file
outside vendored trees and hidden directories (`.github` and `.cursor` included), ignoring
fenced and inline code.

## Agent rules

`AGENTS.md` is the only rule source. `CLAUDE.md` and `GEMINI.md` import it with `@`, and
`.cursor/rules/project-rules.mdc` links it.

## Tests

- `src/base/status_test.cc`: codes and names, factories, `StatusOr` values, move-only values,
  errors, OK-status conversion, the abort on bad access, `AGENT_RETURN_IF_ERROR`.
- `src/build_info/build_info_test.cc`: identity from the build and the version line format.
- `src/cli/cli_test.cc`: commands, help, usage errors, stream separation, exit codes, a failed
  write.
- `tests/CMakeLists.txt`: eight black-box runs of the built binary checking exit code, stdout
  and stderr.
- `tools/tests/*_test.sh`: each plan lint defect, status and the task-start / task-close cycle;
  link and anchor checking; the build budget against fixture `/proc` and cgroup files; the
  Makefile's tag and target checks.
