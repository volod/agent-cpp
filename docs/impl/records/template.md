# Task record: <task-id>

<!-- `make task-start TASK=<task-id>` fills every placeholder under "Task and scope" and drops
this comment. By hand: copy to NNNN-<task-id>.md with the next sequence number, index it in
README.md, and fill the placeholders. Keep evidence concise and the accepted task text
complete. -->

## Task and scope

- Task / capability: `<task-id>` / `<capability-id>`
- State: active
- Source: plan task; commit `<commit>` at start; dirty files: <dirty files>
- Plan counts at start: <plan counts>
- Targets: <targets>
- Accepted task:

  ```markdown
<accepted task block>
  ```

- Amendments: none, or each revised block with its reason and who authorized it.

## Implementation

Changed modules and behavior, reused code, rejected alternatives, compatibility effects
(public headers, CLI contract, presets, dependency pins), limitations, and the current-state
page link.

## Decisions

`none`, or each decision record (`docs/design/adr/NNNN-...`) this task added, superseded or
relied on, with one line on why.

## Acceptance evidence

| Gate | Exact command, test or artifact | Target | Result and limit |
| --- | --- | --- | --- |
| Each acceptance gate | Reproducible evidence | `linux-amd64` | pass, fail, not-run, blocked or valid-negative |

Every target in the task's `Targets` field has a row. Missing, mocked or stale evidence does
not prove acceptance.

## Audit handoff

`none identified` with the reviewed scope and the
[review checklist](../../guide/cpp-review-checklist.md) items that applied, or one entry per
`AUD-<task-id>-N`: the observation, blocking or nonblocking, its evidence and impact, and
exactly one owner (a plan task or a checkpoint). A checkpoint also records an
invariant-to-evidence table, the disposition of every incoming note, a refactor verdict, and
`proceed`, `proceed-with-nonblocking-notes` or `blocked`.

## Close or resume

Gates passed and remaining, the next action, current-page and index updates, plan counts after,
and capability status changes. Set `- State: accepted` only when every gate above passes, then
run `make task-close TASK=<task-id>`.
