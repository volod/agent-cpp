# agent-cpp Implementation Plan

Forward-only: this file holds only work that remains. Product behavior, boundaries and
evaluation belong in the [specification](../design/spec.md); task shape, statuses, ordering and
records in the [planning workflow](../guide/planning-workflow.md); available behavior in
[current state](current.md). Run `make plan-status` for counts and the next eligible task.

Every task keeps `make ci` green, adds deterministic, network-free tests, runs `make cross` for
each device target it names, and adds each new library to the
[dependency table](../design/spec.md#dependencies) in the same change.

## Agent Implementation Tasks

#### personalize-template-project

Give a repository created from this template its own identity before any product work starts.

- Serves: `project-identity` -- [Project identity](../design/spec.md#project-identity)
- Status: CLEAR
- Dependencies: none.
- Outcome: The project, executable, README and specification name and describe the new product;
  `<name> version` prints the new name and repository URL on every target.
- Scope: Take the product name, repository URL, one-line description and preferred code prefix
  from the owner, or derive the URL from `git remote get-url origin`. Rename the `project()`
  name, `DESCRIPTION` and `HOMEPAGE_URL` in `CMakeLists.txt`; the executable in
  `src/CMakeLists.txt`, `tests/CMakeLists.txt` and the release workflow; and, when the owner
  wants a new prefix, the `agent` namespace, `AGENT_` header guards, macros and CMake options,
  `agent_cc_*` helpers and `agent::` aliases. Rewrite the README, the purpose, scope and
  identity sections of the specification and the project line of `AGENTS.md`. Keep the
  version, targets, tooling, gates and documentation lifecycle; add no capabilities, libraries
  or architecture.
- Targets: `linux-amd64`, `rpi5`, `luckfox-pico`.
- Acceptance: `git grep -n -i -e agent-cpp -e agent_ -e 'agent::'` finds no reference that
  denotes the active project (records excepted); `make format`, `make ci` and `make cross`
  pass; `./build/host-debug/src/<name> version` prints the new name and repository URL;
  `project-identity` is `shipped` with a new `docs/impl/current/project-identity.md` linked from
  [current state](current.md). A negative result names the missing owner input instead of
  inventing it.

## Human-Assisted Tasks

#### hardware-smoke-test

- Serves: `multi-target-build` -- [Multi-target build](../design/spec.md#multi-target-build)
- Status: BLOCKED BY HUMAN
- Dependencies: none.
- Request: Run `make dist TARGET=rpi5` and `make dist TARGET=luckfox-pico`, copy each archive to
  a Raspberry Pi 5 (64-bit Raspberry Pi OS) and a Luckfox Pico (vendor Buildroot image), and
  paste the output of `bin/agent-cpp version`, `bin/agent-cpp; echo $?` and `uname -a` from
  each board into a task record. The check passes when both print the expected version line
  and exit code `2`; it completes the `multi-target-build` capability.
