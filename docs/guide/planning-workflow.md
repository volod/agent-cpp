# Planning Workflow

[AGENTS.md](../../AGENTS.md) gives the task cycle. Read only the section you need here.
`make lint-spec-plan` parses the formats below line by line (`tools/plan.sh`), so keep
headings, `- Field:` prefixes and table rows exact.

## The discovery circle

Every piece of work goes around the same loop, and each step has one home:

```text
observe a need --> classify once --> specify (spec.md) --> register and plan (plan.md)
      ^                                                              |
      |                                                              v
 route new findings <-- close (record, current page) <-- build and verify (record evidence)
```

A need discovered during work is classified once: a chore (do it now or drop it), part of the
current task's self-review, more work for a registered capability (a new task), a decision that
outlives the task (a [decision record](../design/adr/README.md)), or a new capability.

## Capability changes

A new or misshaped capability goes through these steps before any plan task or code:

1. State the operator or user problem, not an implementation preference.
2. Amend the owning section of the [specification](../design/spec.md), or a page copied from
   the [page template](../design/template.md): behavior, what it does not do, the targets it
   must run on, evaluation, the acceptance signal and a valid negative result.
3. Add a `planned` row to the [capability registry](../design/spec.md#capability-registry) in
   implementation order.
4. Add its tasks to the plan, in either lane.
5. When its last task is accepted, mark the row `shipped` and link its current-state page.

## Task shape

A task is a `####` heading with a stable lowercase slug under its lane heading, a one- or
two-sentence problem statement, and fields. Field values may continue on following lines.

```markdown
## Agent Implementation Tasks

#### stable-task-id

State the unresolved problem in one or two sentences.

- Serves: `capability-id` -- [Owning spec section](../design/spec.md#section)
- Status: CLEAR
- Dependencies: Open task ids in backticks, or accepted record links; `none.` when there are none.
- Outcome: What becomes possible or trustworthy for the user.
- Scope: Included and excluded behavior, paths, modules, fixtures and declared runs.
- Targets: Backticked target ids whose evidence acceptance needs, e.g. `linux-amd64`, `rpi5`.
- Acceptance: Checks, the acceptance signal and the valid negative result.
```

`Serves` starts with a capability id from the registry. `Targets` lists ids from the
[target table](../design/spec.md#targets). Name every target whose behavior the task can
change: platform code, integer widths, file formats, performance or memory budgets, toolchain
or CMake changes. A task that only touches documentation or tooling names `linux-amd64`.

Human tasks sit under `## Human-Assisted Tasks` and use four fields:

```markdown
#### stable-task-id

- Serves: `capability-id` -- [Owning spec section](../design/spec.md#section)
- Status: HUMAN-GATED
- Dependencies: Open task ids or record links, or `none.`
- Request: What the human provides or decides, how to check it, and what it unblocks.
```

## Task lanes

| Lane | Status | Acceptance needs |
| --- | --- | --- |
| Agent Implementation Tasks | `CLEAR` | Local code, tests and docs; `make ci` and `make cross` |
| Agent Implementation Tasks | `RUN NEEDED` | A declared heavier run (GPU, network, long benchmark, `make matrix`) |
| Human-Assisted Tasks | `BLOCKED BY HUMAN` | Human-provided input or access (hardware, credentials, data) |
| Human-Assisted Tasks | `HUMAN-GATED` | Human judgment, authorization or spending decision |

An agent task that depends on a human task stays ineligible until the decision is recorded.
Agents never approve a human task themselves. Running on a real Raspberry Pi or Luckfox board
is human-assisted unless the owner provides remote access and says so in the task.

## Ordering

Plan order is implementation order: tasks of earlier registry capabilities first; within a
capability, prerequisites first, work that changes later inputs next, cheap deterministic work
before expensive runs, refinements and checkpoints last. Change priority by moving tasks, never
by task wording. Dependencies must resolve to open tasks or existing records; `make plan-status`
reports the first task whose dependencies are all closed and what else may run in parallel.
Dependencies that form a cycle leave every task in it ineligible.

## Durable task records

`make task-start TASK=<id>` copies the [record template](../impl/records/template.md) to
`docs/impl/records/NNNN-<task-id>.md`, where `NNNN` is one more than the highest existing
record, fills in the verbatim task, commit, dirty files, plan counts and targets, and indexes it
in the [records README](../impl/records/README.md). Running it again for the same task prints
the existing record, which is how an interrupted task resumes. The record keeps the full
original task and any amendments after the task leaves the plan, plus evidence and decisions.
Its first scope line, `- Task / capability: `, names the task id from its file name. Current
pages describe available behavior and link records. Future work goes to the plan with one
owner.

A record's `- State:` is `active`, `blocked` or `accepted`. Only the agent that verified every
acceptance gate sets `accepted`; `make task-close` refuses anything else.

## Audit notes and checkpoints

Self-review every task against the [C++ review checklist](cpp-review-checklist.md) and record
`none identified` or notes `AUD-<task-id>-N` with evidence. Route a concern outside the task's
scope to exactly one owner: a blocking repair task placed before dependent work, or a named
checkpoint task for nonblocking concerns. Do not broaden the current task.

A checkpoint task reviews the records, code, tests and notes routed to it. It records an
invariant-to-evidence table, each note's disposition, a refactor verdict, and `proceed`,
`proceed-with-nonblocking-notes` or `blocked`. A blocker keeps the checkpoint open until its
repair passes.

## Completion transition

Before closing, map every acceptance gate and target to evidence in the record, route every
note, and link the record from the current-state page. `make task-close TASK=<id>` then removes
the task, writes `None open.` under a lane it emptied, replaces backticked references to its id
in the plan with the record link, marks the index row `accepted`, reruns the plan lint and
prints the new counts; when it reports that the capability has no open tasks, mark the registry
row `shipped`. Never put completion notes, dates, measurements or history in `plan.md`. Failed
acceptance leaves the task open, with partial results and the next action in its record.

## What the lint checks

`make lint-spec-plan` fails when:

- a registry row is listed twice, has a status other than `planned` or `shipped`, is `planned`
  without open tasks, or is `shipped` with open tasks or without a `docs/impl/current/` link;
- a task id repeats, a required field is empty, a status is not valid in its lane, `Serves`
  names no registered capability, a dependency is neither an open task nor an existing record,
  or `Targets` names an id missing from the target table;
- a record is not named `NNNN-<task-id>.md`, reuses a sequence number, names another task on
  its first scope line, is missing from the records README, or is `accepted` while its task is
  still in the plan.
