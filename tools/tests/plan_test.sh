#!/bin/sh
# Tests of tools/plan.sh on throwaway repositories: status, every lint defect, task-start and
# task-close.
set -eu
# shellcheck source=lib.sh
. "$(dirname -- "$0")/lib.sh"

# A consistent repository: two agent tasks (the second depends on the first) and one human task.
fixture() {
  dir=$scratch/$1
  rm -rf "$dir"
  mkdir -p "$dir/docs/design" "$dir/docs/impl/records"
  cat >"$dir/docs/design/spec.md" <<'EOF'
# Spec

## Cross-cutting rules

### Targets

| Target id | Hardware |
| --- | --- |
| `linux-amd64` | PC |
| `rpi5` | Raspberry Pi 5 |

## Capability Registry

| # | Capability | Status | How it is evaluated | Implementation |
| --- | --- | --- | --- | --- |
| 1 | `core` | planned | tests | [Open work](../impl/plan.md) |
| 2 | `done` | shipped | tests | [Current](../impl/current/done.md) |
EOF
  cat >"$dir/docs/impl/plan.md" <<'EOF'
# Plan

## Agent Implementation Tasks

#### first

Do the first thing.

- Serves: `core` -- [Core](../design/spec.md)
- Status: CLEAR
- Dependencies: none.
- Outcome: It works.
- Scope: Only this,
  continued on a second line.
- Targets: `linux-amd64`, `rpi5`.
- Acceptance: Tests pass.

#### second

- Serves: `core`
- Status: RUN NEEDED
- Dependencies: `first`.
- Outcome: More works.
- Scope: Only that.
- Targets: `linux-amd64`.
- Acceptance: Tests pass.

## Human-Assisted Tasks

#### ask

- Serves: `core`
- Status: HUMAN-GATED
- Dependencies: none.
- Request: Decide.
EOF
  printf '# Records\n\n| Record | Task | Result |\n| --- | --- | --- |\n' \
    >"$dir/docs/impl/records/README.md"
  cp "$repo/docs/impl/records/template.md" "$dir/docs/impl/records/template.md"
  git -C "$dir" init -q
}

plan() {
  sh "$tools/plan.sh" -C "$dir" "$@"
}

# defect <name> <file under docs/> <sed script> <expected problem>
defect() {
  fixture defect
  sed -i "$3" "$dir/docs/$2"
  expect "lint: $1" 1 "$4" plan lint
}

fixture base
expect "lint: consistent repository" 0 "lint-spec-plan: ok" plan lint
expect "status: counts" 0 "open tasks: 3 (2 agent, 1 human)" plan status
expect "status: next" 0 "next agent task: first (core, CLEAR)" plan status
expect "status: human" 0 "human action available: ask (HUMAN-GATED)" plan status
expect "usage" 2 "usage:" plan frobnicate

defect "duplicate id" impl/plan.md 's/^#### second$/#### first/' 'duplicate task id "first"'
defect "missing field" impl/plan.md '/^- Outcome: It works/d' 'missing field "Outcome"'
defect "bad status" impl/plan.md 's/^- Status: CLEAR$/- Status: READY/' 'status "READY" is not valid'
defect "agent status in human lane" impl/plan.md 's/HUMAN-GATED/CLEAR/' 'not valid in the human lane'
defect "Serves without id" impl/plan.md 's/^- Serves: `core` -- /- Serves: core /' \
  'Serves must start with a backticked capability id'
defect "unknown capability" impl/plan.md '0,/`core`/s//`nope`/' 'serves "nope"'
defect "unknown dependency" impl/plan.md 's/`first`\./`ghost`./' 'dependency `ghost` is not an open task'
defect "missing record dependency" impl/plan.md 's/`first`\./[0009-x](records\/0009-x.md)./' \
  'dependency record 0009-x.md does not exist'
defect "unknown target" impl/plan.md 's/`rpi5`/`pdp11`/' 'unknown target `pdp11`'
defect "Targets without ids" impl/plan.md 's/^- Targets: `linux-amd64`\.$/- Targets: host./' \
  'Targets must list backticked target ids'
defect "registry status" design/spec.md 's/| planned |/| wip |/' 'want planned or shipped'
defect "registry duplicate" design/spec.md '$a| 3 | `core` | planned | x | y |' \
  'capability "core" is listed twice'
defect "planned without tasks" design/spec.md '$a| 3 | `idle` | planned | x | y |' \
  'is planned but has no open tasks'
defect "shipped with tasks" impl/plan.md 's/^- Serves: `core`$/- Serves: `done`/' \
  'is shipped but has 2 open task(s)'
defect "shipped without page" design/spec.md 's/(..\/impl\/current\/done.md)/(..\/impl\/plan.md)/' \
  'links no docs/impl/current/ page'

fixture records
printf -- '- Task / capability: `x` / `core`\n' >"$dir/docs/impl/records/1-x.md"
expect "record: bad name" 1 "1-x.md: name must be NNNN-<task-id>.md" plan lint
rm "$dir/docs/impl/records/1-x.md"
printf -- '- Task / capability: `y` / `core`\n- State: active\n' >"$dir/docs/impl/records/0001-x.md"
expect "record: id line" 1 'first scope line must be "- Task / capability: `x`' plan lint
expect "record: not indexed" 1 "0001-x.md: not linked from the records README" plan lint
printf -- '- Task / capability: `first` / `core`\n- State: accepted\n' \
  >"$dir/docs/impl/records/0001-first.md"
expect "record: duplicate sequence" 1 "sequence 0001 is already used" plan lint
expect "record: accepted while open" 1 'accepted, but task "first" is still in the plan' plan lint

fixture cycle
expect "start: creates record" 0 "created docs/impl/records/0001-first.md" plan start first
record=$dir/docs/impl/records/0001-first.md
assert "start: id line" grep -qx -e '- Task / capability: `first` / `core`' "$record"
assert "start: targets" grep -qx -e '- Targets: `linux-amd64`, `rpi5`' "$record"
assert "start: counts" grep -q 'next eligible `first`' "$record"
assert "start: verbatim task" grep -qx -e '    continued on a second line.' "$record"
assert "start: comment dropped" sh -c "! grep -q '<!--' '$record'"
assert "start: no placeholder left" sh -c "! grep -q '<task-id>\|<accepted task block>' '$record'"
assert "start: indexed" grep -qF '| [0001-first](0001-first.md) | `first` | active |' \
  "$dir/docs/impl/records/README.md"
expect "start: lint after start" 0 "lint-spec-plan: ok" plan lint
expect "start: resumes" 0 "resuming docs/impl/records/0001-first.md" plan start first
expect "start: blocked" 1 'blocked by open task(s): first' plan start second
expect "start: human task" 1 "is a human task" plan start ask
expect "start: unknown task" 1 'task "ghost" is not in docs/impl/plan.md' plan start ghost

expect "close: no record" 1 "has no record" plan close second
expect "close: not accepted" 1 "record 0001-first.md is not accepted" plan close first
sed -i 's/^- State: active$/- State: accepted/' "$record"
expect "close: closes" 0 "next agent task: second (core, RUN NEEDED)" plan close first
assert "close: task removed" sh -c "! grep -q '^#### first' '$dir/docs/impl/plan.md'"
assert "close: reference rewritten" grep -qF -- '- Dependencies: [0001-first](records/0001-first.md).' \
  "$dir/docs/impl/plan.md"
assert "close: index accepted" grep -qF '| [0001-first](0001-first.md) | `first` | accepted |' \
  "$dir/docs/impl/records/README.md"
expect "close: lint after close" 0 "lint-spec-plan: ok" plan lint

expect "start: next sequence" 0 "created docs/impl/records/0002-second.md" plan start second
sed -i 's/^- State: active$/- State: accepted/' "$dir/docs/impl/records/0002-second.md"
plan close second >/dev/null 2>&1 || true
assert "close: emptied lane" grep -qx 'None open.' "$dir/docs/impl/plan.md"
assert "close: human lane kept" grep -qx '#### ask' "$dir/docs/impl/plan.md"

finish
