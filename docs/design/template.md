# Capability name

<!-- Copy to docs/design/<capability-id>.md when a capability outgrows its section in spec.md,
link the page from that section, replace every <placeholder> and delete this comment. -->

- Capability: `<capability-id>` in the [registry](spec.md#capability-registry)
- Problem: what an operator or user cannot do or trust today, in their terms.
- Targets: which [targets](spec.md#targets) must support it, and why any is excluded.

## Behavior

Commands, flags and defaults; inputs and outputs; file formats; error cases, status codes and
exit codes. Mark contracts that other capabilities consume.

## Boundaries

What this capability does not do, and which capability owns the adjacent behavior.

## Design

Modules and edges from the [architecture](architecture.md); public types and `Status` codes;
data flow, ownership, state, concurrency and cancellation; memory and CPU limits on the smallest
target (Luckfox Pico: 64-256 MB RAM); new libraries from the
[dependency table](spec.md#dependencies); decision records it adds or relies on.

## Evaluation

| Gate | Evidence | Targets |
| --- | --- | --- |
| Acceptance signal | Deterministic test, fixture or declared run that proves it | `linux-amd64`, ... |

Valid negative result: what a supported "no" looks like and what it leaves in place.
