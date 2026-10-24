# Project rules

Canonical rules for every agent and contributor. `CLAUDE.md`, `GEMINI.md` and `.cursor/rules/`
only point here; never put rules in them. Read the selected task, the code it touches and the
design sections it links. Load other guidance only when a condition under
[Read when needed](#read-when-needed) applies.

## Project

`agent-cpp` is a template for C++20 command-line and device projects built by people and coding
agents, for amd64 hosts, Raspberry Pi 5 (aarch64) and Luckfox Pico (armv7). The
[specification](docs/design/spec.md) says what the product must do and how each capability is
evaluated, the [architecture](docs/design/architecture.md) owns modules and dependency
direction, [decision records](docs/design/adr/README.md) keep choices that outlive one task, the
[plan](docs/impl/plan.md) holds only remaining work, [task records](docs/impl/records/README.md)
keep evidence, and [current state](docs/impl/current.md) describes what exists.

## Guardrails

- Preserve unrelated work. Diagnostic or review requests do not authorize code changes.
- Do not commit, push, rewrite history or revert user changes unless explicitly asked.
- C++20 on GCC >= 13 or Clang >= 18, CMake >= 3.28, Ninja; Ubuntu 24.04 and 26.04 are the
  supported development hosts, prepared once with `tools/setup-ubuntu.sh`; build and gate
  commands refuse to run on an unprepared system. Run gates through `make` (`make help`); each
  step is a plain command listed in the [development guide](docs/guide/development.md#commands).
- Prefer the standard library. Add a third-party library only after adding it to the
  [dependency table](docs/design/spec.md#dependencies), pinned by version and hash.
- Never hardcode machine-specific paths; resolve from the repository root or a preset. Never
  put secrets in code, logs, fixtures or docs. Use ASCII in code, logs and docs.
- Never weaken a gate to make it pass: no `NOLINT` without a reason, no disabled warnings, no
  skipped tests. Fix the cause or stop and report.

## Stop and ask

Stop, record the state in the task record, and ask the owner when:

- the specification is ambiguous or contradicts the task, or acceptance needs a decision that
  is not written down;
- the work needs a new dependency, target, toolchain, or a change to a decision record;
- a gate cannot pass without weakening it, or a required tool is missing and cannot be
  installed with `tools/setup-ubuntu.sh`;
- the change grows beyond the task's scope boundary (route the extra work instead; see
  [audit rules](docs/guide/planning-workflow.md#audit-notes-and-checkpoints)).

## C++ conventions

Follow the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html);
`.clang-format` and `.clang-tidy` enforce what tools can check.

- **Layout.** One directory per module under `src/` holding `name.h`, `name.cc`,
  `name_test.cc` and a `CMakeLists.txt` that declares targets only with `agent_cc_library`,
  `agent_cc_binary` and `agent_cc_test` (`cmake/AgentTargets.cmake`). Includes are rooted at `src/`
  (`#include "base/status.h"`); guards are `AGENT_<DIR>_<FILE>_H_`. Code lives in namespace
  `agent`, with a module namespace (`agent::cli`) when its names are generic. Name modules for what
  they provide; no `utils`, `common` or `helpers`. Follow the
  [dependency direction](docs/design/architecture.md#dependency-direction).
- **Edges.** `src/main.cc` only wires the process and calls `cli::Run`. Only `cli` writes to
  stdout or stderr, reads the environment, and decides exit codes. Other modules take typed
  input, return values, and never print, exit or abort on expected failures.
- **Errors.** No exceptions: never `throw` or `catch`. A fallible function returns
  `agent::Status` or `agent::StatusOr<T>` (`src/base/status.h`); callers branch on `code()`, never
  on message text. `std::abort` (with a message) is only for broken invariants. See
  [ADR 0001](docs/design/adr/0001-errors-as-values.md).
- **Ownership.** Values first, then `std::unique_ptr`; no owning raw pointers, no `new` or
  `delete`. Take `std::string_view`, `std::span<const T>` or `const T&` for read-only input and
  return owned values. No global mutable state: pass streams, clocks and paths in.
- **Portability.** Code runs on 64-bit and 32-bit Arm: `long` and `std::size_t` are 32 bits on
  armv7. Use fixed-width integers for data that crosses a file, wire or device boundary, check
  narrowing explicitly, and never rely on endianness, alignment or `-march=native`. Platform
  code goes in dedicated `name_linux.cc`-style files selected in CMake, not scattered `#if`s.
- **Concurrency.** Single-threaded until a capability specifies concurrency; then use
  `std::jthread` owned by the function that starts it, keep output order deterministic, and add
  a ThreadSanitizer run to the task's acceptance gates.
- **Comments.** Every header starts with a comment saying what the module provides; every
  public declaration says what it does, its preconditions and its error codes. Comments explain
  why, not what the code already says.
- **Tests.** GoogleTest. Unit tests sit beside their source as `name_test.cc`; black-box tests of
  the built binary live in `tests/`. Tests are table-driven, deterministic and network-free,
  build fixtures under `testing::TempDir()`, and assert behavior, not implementation details. A
  bug fix starts with a failing regression test.
- Keep files at about 400 lines or less; split at real seams.

## Heavy compilation (Ninja / CMake / CUDA)

- **Budget.** Parallelism comes only from `cmake/AgentBuildBudget.cmake`, which sizes the
  compile, link and heavy Ninja pools from free memory, CPUs and cgroup limits whenever CMake
  configures; `make jobs` prints it. Never inline the formula, pass a bare `-j` to Ninja or
  `make`, or raise `AGENT_MAX_JOBS` above what it reports.
- **Pools.** A translation unit that needs gigabytes (nvcc, CUTLASS- or Eigen-style templates,
  large generated code) is declared `HEAVY` or `CUDA` in its `agent_cc_*` call so it compiles in
  the `heavy` Ninja pool while ordinary code keeps full parallelism.
- **CUDA.** Opt-in with the `host-cuda` preset (`AGENT_ENABLE_CUDA=ON`), host only. Set explicit
  `CMAKE_CUDA_ARCHITECTURES` (`AGENT_CUDA_ARCHITECTURES=89`; `native` only on a workstation);
  `all` and `all-major` are rejected. Point `CUDAHOSTCXX` at a host compiler the installed nvcc
  supports. CUDA code stays behind a module boundary so cross targets build without it.
- **Heavy third-party libraries** (OpenCV, ONNX Runtime, Torch, gRPC): prefer the distribution
  package, then an official prebuilt archive. Build from source only through a cached install
  prefix `.cache/deps/<target>/<name>-<version>-<key>/`, where `<key>` hashes the toolchain file,
  compiler version and build flags, consumed through `CMAKE_PREFIX_PATH`. Never `FetchContent`
  a heavy library into the product build, and never rebuild one per build directory.
- `ccache` is used automatically when installed (`.cache/ccache`). Builds and caches stay under
  `build/` and `.cache/`; `make matrix` keeps its trees under `build/ubuntu-<version>/`.

## Task cycle

1. **Select.** Run `make plan-status`, take one eligible task and note the counts. Read its
   dependencies and the records they link. Do not start blocked work.
2. **Start.** Run `make task-start TASK=<task-id>`. It creates the numbered record with the
   verbatim task, commit, dirty files and counts, and indexes it. Identify the affected modules
   and reusable code; do not silently broaden scope.
3. **Build.** Implement the smallest slice that meets the acceptance gates, with tests for the
   happy path, the main edge cases and a regression for every bug fixed. Iterate with
   `make check`; run `make cross` for each target in the task's `Targets` field.
4. **Verify.** Run the task's declared checks and `make ci`. Self-review against the
   [C++ review checklist](docs/guide/cpp-review-checklist.md). Record failures and unrun
   checks honestly; missing, mocked or stale evidence does not prove acceptance. Failed
   acceptance keeps the task open.
5. **Close.** Fill the record: evidence per gate and target, decisions (a new ADR when a
   choice outlives the task), audit notes, next action. On acceptance set `- State: accepted`,
   update the narrow `docs/impl/current/` page and link the record, then run
   `make task-close TASK=<task-id>`; it removes the task, points references at the record and
   reruns the plan lint. Mark the capability `shipped` when it reports none left. Run
   `make lint-doc-links`, report counts before and after and the next eligible task, inspect
   `git status` and remove temporary files.

## Read when needed

- **Adding or changing capabilities or tasks:** the
  [planning workflow](docs/guide/planning-workflow.md). Specify behavior and evaluation before
  planning or coding.
- **Concerns outside the task, or a checkpoint task:** the
  [audit rules](docs/guide/planning-workflow.md#audit-notes-and-checkpoints). Route each concern
  to exactly one owner.
- **Human-assisted tasks:** agents prepare inputs and report what is needed; they never mark a
  human task done. See [task lanes](docs/guide/planning-workflow.md#task-lanes).
- **A choice that constrains future work:** add a [decision record](docs/design/adr/README.md).
- **Toolchains, commands, CI, releases or test layout:** the
  [development guide](docs/guide/development.md).
- **Targets, boards, cross compilers or qemu:** the
  [cross-compilation guide](docs/guide/cross-compilation.md).
