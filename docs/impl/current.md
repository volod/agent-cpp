# Current Implementation

This index describes behavior available now. Product intent is in the
[specification](../design/spec.md), remaining work in the [plan](plan.md), decisions in the
[decision records](../design/adr/README.md), and evidence in the
[task records](records/README.md).

## Documentation shape

Each capability gets one page under `current/` when its first task is accepted, linked from the
table below and from its registry row. A page states behavior, modules, commands, targets and
tests, and links the records that prove them. When a page grows, it becomes a short index of
focused pages under `current/<capability>/`. Plans, dates and history do not belong here.

## Areas

| Area | Owns | State |
| --- | --- | --- |
| [Project foundation](current/project-foundation.md) | CMake layout, `agent_cc_*` helpers, `Status`, the `agent-cpp` command seam, `make` gates, build budget, CI, agent rules, planning tooling | Shipped |
| [Multi-target build](current/multi-target-build.md) | Toolchain files, cross presets, static device binaries, qemu-user tests | Emulated; hardware confirmation open |
| [Release distribution](current/release-distribution.md) | `make dist`, archives, checksums, tag release workflow | Shipped |
