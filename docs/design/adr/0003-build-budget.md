# 0003: One build budget with compile, link and heavy job pools

- Status: accepted
- Context links: [AGENTS.md heavy compilation](../../../AGENTS.md#heavy-compilation-ninja--cmake--cuda),
  [development guide](../../guide/development.md#build-budget).

## Context

Unbounded parallel builds exhaust memory: an nvcc or template-heavy translation unit can peak
at 8-12 GB, an LTO link at more, and a Raspberry Pi 5 building natively has 4-8 GB in total.
Agents start builds unattended, often inside containers or systemd slices whose cgroup limits
are lower than the host's. A single global `-j` either starves ordinary code or lets heavy
units run out of memory.

## Decision

- `cmake/AgentBuildBudget.cmake` is the only place that computes parallelism. It runs at
  configure time, so every configure (preset, `make`, IDE or plain `cmake`) gets the same
  budget, and `cmake -P cmake/AgentBuildBudget.cmake` (`make jobs`) prints it.
- Each pool has a peak memory per job and a CPU share: `compile` 2 GB and every usable core,
  `link` 4 GB and half, `heavy` 12 GB and half. Usable memory is `MemAvailable` less 20 percent
  of the total; two cores stay reserved. Memory and CPUs honor the CPU affinity mask and the
  cgroup v2 `memory.max` and `cpu.max` of the process's cgroup and its ancestors.
- The pools become Ninja job pools: `compile` and `link` for every target, `heavy` for targets
  declared `HEAVY` or `CUDA` in `agent_cc_*`. `AGENT_MAX_JOBS` in the environment can only
  lower them.
- Heavy third-party libraries are built at most once per target and toolchain into a cached
  install prefix under `.cache/deps/`, never through FetchContent in the product build.

## Alternatives

- Computing the budget in a script that exports variables before CMake runs: one more language
  to install and test, and a plain `cmake --preset` without the script would build without
  pools.
- `cmake_host_system_information` alone: reports host memory and cores, not cgroup limits or
  the affinity mask, which is exactly the container case agents run in.
- One global `-j` from `nproc`: the failure this record exists to prevent.
- Per-developer settings: not reproducible, and agents do not know them.

## Consequences

Builds are safe by default on workstations, CI runners, containers and boards, with or without
`make`. The budget is fixed when CMake configures; `make check` reconfigures on every run, a
long-lived IDE build tree keeps its configure-time budget until it reconfigures. cgroup v1
limits are not read; Ubuntu 24.04 and later use cgroup v2. Revisit the per-job figures when a
heavy dependency is added: measure its peak resident memory and adjust the pool in the same
change.
