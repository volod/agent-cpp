#!/bin/sh
# Planning commands over the capability registry and target table (docs/design/spec.md), the
# plan (docs/impl/plan.md) and the task records (docs/impl/records/). The formats are defined
# in docs/guide/planning-workflow.md.
#
#   tools/plan.sh [-C <root>] status | lint | start <task-id> | close <task-id>
#
# Exit codes: 0 success, 1 a check failed or the command refused, 2 usage error.
set -eu

usage() {
  echo "usage: tools/plan.sh [-C <root>] status | lint | start <task-id> | close <task-id>" >&2
  exit 2
}

fail() {
  printf 'plan.sh: %s\n' "$1" >&2
  exit 1
}

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if [ "${1:-}" = -C ]; then
  [ $# -ge 2 ] || usage
  root=$2
  shift 2
fi
spec=$root/docs/design/spec.md
plan=$root/docs/impl/plan.md
records=$root/docs/impl/records
index=$records/README.md
template=$records/template.md

# One tab-separated line per fact, in document order:
#   cap     <id> <status> <links current page 0|1> <spec line>
#   target  <id>
#   task    <id> <lane> <plan line> <status> <capability> <deps> <record deps> <targets>
#           <missing fields> <Targets value present 0|1>      (lists are comma-separated)
#   record  <file> <sequence> <id from name> <id from body> <state> <indexed 0|1> <name ok 0|1>
MODEL_AWK='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function ids(s,   out, sep) {
  out = ""; sep = ""
  while (match(s, /`[a-z0-9][a-z0-9-]*`/)) {
    out = out sep substr(s, RSTART + 1, RLENGTH - 2); sep = ","
    s = substr(s, RSTART + RLENGTH)
  }
  return out
}
function record_links(s,   out, sep) {
  out = ""; sep = ""
  while (match(s, /\(records\/[0-9][0-9][0-9][0-9]-[a-z0-9][a-z0-9-]*\.md/)) {
    out = out sep substr(s, RSTART + 9, RLENGTH - 9); sep = ","
    s = substr(s, RSTART + RLENGTH)
  }
  return out
}
function end_task(   required, n, i, missing, sep) {
  if (task == "") return
  required = lane == "agent" ? "Serves Status Dependencies Outcome Scope Targets Acceptance" \
                             : "Serves Status Dependencies Request"
  n = split(required, names, " ")
  missing = ""; sep = ""
  for (i = 1; i <= n; i++)
    if (val[names[i]] == "") { missing = missing sep names[i]; sep = "," }
  capability = ids(val["Serves"]); sub(/,.*/, "", capability)
  print "task\t" task "\t" lane "\t" task_line "\t" val["Status"] "\t" capability \
        "\t" ids(val["Dependencies"]) "\t" record_links(val["Dependencies"]) "\t" \
        ids(val["Targets"]) "\t" missing "\t" (val["Targets"] != "")
  task = ""
}
function end_record() {
  if (rec == "") return
  print "record\t" rec "\t" substr(rec, 1, 4) "\t" substr(rec, 6, length(rec) - 8) "\t" \
        body_id "\t" state "\t" (index(index_text, "](" rec ")") > 0) "\t" \
        (rec ~ /^[0-9][0-9][0-9][0-9]-[a-z0-9][a-z0-9-]*\.md$/)
  rec = ""
}
{ gsub(/\t/, " ") }
FILENAME != plan { end_task() }
FILENAME == spec {
  if (/^## /) { section = trim($0); sub3 = ""; header = 0; next }
  if (/^### /) { sub3 = trim(substr($0, 5)); next }
  if (!/^\|/) next
  n = split($0, cell, "|")
  if (section == "## Capability Registry") {
    if (!header) {
      for (i = 2; i < n; i++) {
        if (trim(cell[i]) == "Status") status_col = i
        if (trim(cell[i]) == "Implementation") impl_col = i
      }
      header = 1
      next
    }
    for (i = 2; i < n; i++) {
      c = trim(cell[i])
      if (c ~ /^`[a-z0-9][a-z0-9-]*`$/) {
        print "cap\t" substr(c, 2, length(c) - 2) "\t" trim(cell[status_col]) "\t" \
              (cell[impl_col] ~ /impl\/current\//) "\t" FNR
        break
      }
    }
  } else if (sub3 == "Targets" && trim(cell[2]) ~ /^`[a-z0-9][a-z0-9-]*`$/) {
    print "target\t" substr(trim(cell[2]), 2, length(trim(cell[2])) - 2)
  }
  next
}
FILENAME == plan {
  if (/^#/) end_task()
  if (/^## /) {
    h = trim($0)
    lane = h == "## Agent Implementation Tasks" ? "agent" : h == "## Human-Assisted Tasks" ? "human" : ""
    next
  }
  if (/^#### / && lane != "") {
    t = trim(substr($0, 6))
    if (t ~ /^[a-z0-9][a-z0-9-]*$/) {
      task = t; task_line = FNR; field = ""
      split("", val)
    }
    next
  }
  if (task == "") next
  if (match($0, /^- [A-Z][A-Za-z ]*:/)) {
    field = substr($0, 3, RLENGTH - 3)
    val[field] = trim(substr($0, RLENGTH + 1))
  } else if ($0 ~ /^[ \t]*$/) {
    field = ""
  } else if (field != "") {
    val[field] = trim(val[field] " " trim($0))
  }
  next
}
FILENAME == index_file { index_text = index_text "\n" $0; next }
FNR == 1 {
  end_record()
  rec = FILENAME; sub(/.*\//, "", rec)
  body_id = ""; state = ""
}
/^- Task \/ capability: `/ && body_id == "" {
  body_id = $0; sub(/^- Task \/ capability: `/, "", body_id); sub(/`.*/, "", body_id)
}
/^- State: / && state == "" {
  state = $0; sub(/^- State: `?/, "", state); sub(/[^a-z-].*/, "", state)
}
END { end_task(); end_record() }
'

model() {
  for f in "$spec" "$plan" "$index"; do
    [ -f "$f" ] || fail "missing ${f#"$root"/}"
  done
  set -- "$spec" "$plan" "$index"
  for f in "$records"/*.md; do
    case ${f##*/} in README.md | template.md | '*.md') continue ;; esac
    set -- "$@" "$f"
  done
  awk -v spec="$spec" -v plan="$plan" -v index_file="$index" "$MODEL_AWK" "$@"
}

# Open tasks with no open dependency are eligible; accepted records never block.
STATUS_AWK='
BEGIN { FS = "\t" }
$1 == "task" { n++; id[n] = $2; lane[n] = $3; status[n] = $5; cap[n] = $6; deps[n] = $7; open[$2] = 1 }
END {
  for (i = 1; i <= n; i++) {
    ready = 1
    k = split(deps[i], d, ",")
    for (j = 1; j <= k; j++) if (d[j] in open) ready = 0
    if (lane[i] == "agent") {
      agent++
      if (ready) eligible[++ne] = i
    } else {
      human++
      if (ready) waiting[++nw] = i
    }
  }
  if (mode == "counts") {
    print (agent + human) " open (" agent + 0 " agent, " human + 0 " human); next eligible " \
          (ne ? "`" id[eligible[1]] "`" : "none")
    exit
  }
  print "open tasks: " (agent + human) " (" agent + 0 " agent, " human + 0 " human)"
  if (ne) {
    print "next agent task: " id[eligible[1]] " (" cap[eligible[1]] ", " status[eligible[1]] ")"
    if (ne > 1) {
      line = "also eligible: " id[eligible[2]]
      for (i = 3; i <= ne; i++) line = line ", " id[eligible[i]]
      print line
    }
  } else {
    print "next agent task: none eligible"
  }
  for (i = 1; i <= nw; i++)
    print "human action available: " id[waiting[i]] " (" status[waiting[i]] ")"
}
'

LINT_AWK='
BEGIN {
  FS = "\t"; S = "docs/design/spec.md"; P = "docs/impl/plan.md"; R = "docs/impl/records/"
  valid["agent", "CLEAR"] = valid["agent", "RUN NEEDED"] = 1
  valid["human", "HUMAN-GATED"] = valid["human", "BLOCKED BY HUMAN"] = 1
}
function problem(msg) { print msg > "/dev/stderr"; problems++ }
$1 == "cap" {
  if ($2 in cap) problem(S ":" $5 ": capability \"" $2 "\" is listed twice")
  ncap++; cap_id[ncap] = $2; cap[$2] = $3; cap_page[$2] = $4; cap_line[$2] = $5
}
$1 == "target" { target[$2] = 1 }
$1 == "task" {
  if ($2 in open) problem(P ":" $4 ": duplicate task id \"" $2 "\"")
  n++; open[$2] = 1
  t_id[n] = $2; t_lane[n] = $3; t_line[n] = $4; t_status[n] = $5; t_cap[n] = $6
  t_deps[n] = $7; t_recs[n] = $8; t_targets[n] = $9; t_missing[n] = $10; t_has_targets[n] = $11
  tasks_of[t_cap[n]]++
}
$1 == "record" {
  nr++; r_file[nr] = $2; r_seq[nr] = $3; r_id[nr] = $4; r_body[nr] = $5; r_state[nr] = $6
  r_indexed[nr] = $7; r_ok[nr] = $8; record[$2] = 1
}
END {
  if (!ncap) problem(S ": no capabilities in the Capability Registry table")
  for (i = 1; i <= ncap; i++) {
    c = cap_id[i]; where = S ":" cap_line[c] ": capability \"" c "\""
    if (cap[c] != "planned" && cap[c] != "shipped")
      problem(where " has status \"" cap[c] "\", want planned or shipped")
    if (cap[c] == "shipped" && !cap_page[c]) problem(where " is shipped but links no docs/impl/current/ page")
    if (cap[c] == "planned" && !tasks_of[c]) problem(where " is planned but has no open tasks")
    if (cap[c] == "shipped" && tasks_of[c]) problem(where " is shipped but has " tasks_of[c] " open task(s)")
  }
  for (i = 1; i <= n; i++) {
    where = P ":" t_line[i] ": task \"" t_id[i] "\": "
    k = split(t_missing[i], m, ",")
    for (j = 1; j <= k; j++) problem(where "missing field \"" m[j] "\"")
    if (t_status[i] != "" && !((t_lane[i], t_status[i]) in valid))
      problem(where "status \"" t_status[i] "\" is not valid in the " t_lane[i] " lane")
    if (t_cap[i] == "") {
      if (!index(t_missing[i], "Serves")) problem(where "Serves must start with a backticked capability id")
    } else if (!(t_cap[i] in cap)) {
      problem(where "serves \"" t_cap[i] "\", which is not in the Capability Registry")
    }
    k = split(t_deps[i], d, ",")
    for (j = 1; j <= k; j++)
      if (!(d[j] in open)) problem(where "dependency `" d[j] "` is not an open task (link accepted work as records/...)")
    k = split(t_recs[i], d, ",")
    for (j = 1; j <= k; j++)
      if (!(d[j] in record)) problem(where "dependency record " d[j] " does not exist")
    if (t_lane[i] == "agent" && t_has_targets[i]) {
      k = split(t_targets[i], d, ",")
      if (!k) problem(where "Targets must list backticked target ids, e.g. `linux-amd64`")
      for (j = 1; j <= k; j++)
        if (!(d[j] in target)) problem(where "unknown target `" d[j] "` (not in the spec target table)")
    }
  }
  for (i = 1; i <= nr; i++) {
    where = R r_file[i] ": "
    if (!r_ok[i]) { problem(where "name must be NNNN-<task-id>.md"); continue }
    if (r_seq[i] in seq) problem(where "sequence " r_seq[i] " is already used by " seq[r_seq[i]])
    else seq[r_seq[i]] = r_file[i]
    if (r_body[i] != r_id[i]) problem(where "first scope line must be \"- Task / capability: `" r_id[i] "` / ...\"")
    if (!r_indexed[i]) problem(where "not linked from the records README")
    if (r_state[i] == "accepted" && (r_id[i] in open)) problem(where "accepted, but task \"" r_id[i] "\" is still in the plan")
  }
  if (problems) { print "lint-spec-plan: " problems " problem(s)" > "/dev/stderr"; exit 1 }
  print "lint-spec-plan: ok"
}
'

# The model line of `kind` whose column `col` equals `id`, or nothing.
lookup() {
  printf '%s\n' "$1" | awk -F '\t' -v kind="$2" -v col="$3" -v id="$4" \
    '$1 == kind && $col == id { print; exit }'
}

field() {
  printf '%s\n' "$1" | cut -f "$2"
}

# Replaces placeholders with values from the environment, so text needs no escaping.
FILL_AWK='
function replace(s, from, to,   at, out) {
  out = ""
  while ((at = index(s, from)) > 0) { out = out substr(s, 1, at - 1) to; s = substr(s, at + length(from)) }
  return out s
}
!dropped && /^<!--/ { skipping = 1 }
skipping { if (/-->/) { skipping = 0; dropped = 1; blanks = 1 }; next }
blanks && /^[ \t]*$/ { next }
{
  blanks = 0
  n = split("task-id|capability-id|commit|dirty files|plan counts|targets|accepted task block", keys, "|")
  split("TASK_ID|CAPABILITY|COMMIT|DIRTY|COUNTS|TARGETS|BLOCK", vars, "|")
  line = $0
  for (i = 1; i <= n; i++) line = replace(line, "<" keys[i] ">", ENVIRON[vars[i]])
  print line
}
'

start() {
  id=$1
  m=$(model)
  existing=$(lookup "$m" record 4 "$id")
  if [ -n "$existing" ]; then
    echo "resuming docs/impl/records/$(field "$existing" 2)"
    return 0
  fi
  task=$(lookup "$m" task 2 "$id")
  [ -n "$task" ] || fail "task \"$id\" is not in docs/impl/plan.md"
  [ "$(field "$task" 3)" = agent ] || fail "task \"$id\" is a human task; agents never take or close it"
  blocking=$(printf '%s\n' "$m" | awk -F '\t' -v deps="$(field "$task" 7)" '
    $1 == "task" { open[$2] = 1 }
    END { n = split(deps, d, ","); for (i = 1; i <= n; i++) if (d[i] in open) out = out (out ? ", " : "") d[i]; print out }')
  [ -z "$blocking" ] || fail "task \"$id\" is blocked by open task(s): $blocking"

  sequence=$(printf '%s\n' "$m" | awk -F '\t' '$1 == "record" && $3 + 0 > max { max = $3 + 0 }
    END { printf "%04d", max + 1 }')
  name=$sequence-$id.md
  block=$(awk -v id="$id" '
    /^#/ { t = $0; sub(/[ \t]+$/, "", t); if (inside) exit; if (t == "#### " id) inside = 1 }
    inside' "$plan")
  dirty=$(git -C "$root" status --porcelain 2>/dev/null | cut -c4- |
    awk '{ out = out (NR > 1 ? ", " : "") "`" $0 "`" } END { print NR ? out : "none" }')
  TASK_ID=$id \
    CAPABILITY=$(field "$task" 6) \
    COMMIT=$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo unknown) \
    DIRTY=$dirty \
    COUNTS=$(printf '%s\n' "$m" | awk -v mode=counts "$STATUS_AWK") \
    TARGETS=$(field "$task" 9 | sed 's/[^,][^,]*/`&`/g; s/,/, /g') \
    BLOCK=$(printf '%s\n' "$block" | sed 's/^./  &/') \
    awk "$FILL_AWK" "$template" >"$records/$name"
  printf '| [%s](%s) | `%s` | active |\n' "${name%.md}" "$name" "$id" >>"$index"
  echo "created docs/impl/records/$name"
}

close() {
  id=$1
  m=$(model)
  record=$(lookup "$m" record 4 "$id")
  [ -n "$record" ] || fail "task \"$id\" has no record; run make task-start TASK=$id"
  name=$(field "$record" 2)
  [ "$(field "$record" 6)" = accepted ] ||
    fail "record $name is not accepted; set '- State: accepted' only after every acceptance gate has evidence"
  task=$(lookup "$m" task 2 "$id")
  [ -n "$task" ] || fail "task \"$id\" is no longer in docs/impl/plan.md"

  # Drop the task block, point references at the record, and mark an emptied lane.
  awk -v id="$id" -v link="[${name%.md}](records/$name)" '
    function replace(s, from, to,   at, out) {
      out = ""
      while ((at = index(s, from)) > 0) { out = out substr(s, 1, at - 1) to; s = substr(s, at + length(from)) }
      return out s
    }
    { t = $0; sub(/[ \t]+$/, "", t)
      if (t == "#### " id) drop = 1; else if (/^#/) drop = 0
      if (!drop) keep[++n] = $0 }
    END {
      for (i = 1; i <= n; i++) {
        out[++o] = replace(keep[i], "`" id "`", link)
        if (keep[i] == "## Agent Implementation Tasks" || keep[i] == "## Human-Assisted Tasks") {
          j = i + 1
          while (j <= n && keep[j] ~ /^[ \t]*$/) j++
          if (j > n || keep[j] ~ /^## /) { out[++o] = ""; out[++o] = "None open." }
        }
      }
      while (o > 0 && out[o] ~ /^[ \t]*$/) o--
      for (i = 1; i <= o; i++) print out[i]
    }' "$plan" >"$plan.tmp"
  mv "$plan.tmp" "$plan"
  awk -v name="$name" '
    index($0, "](" name ")") { n = split($0, c, "|"); c[n - 1] = " accepted "
      $0 = c[1]; for (i = 2; i <= n; i++) $0 = $0 "|" c[i] }
    { print }' "$index" >"$index.tmp"
  mv "$index.tmp" "$index"

  capability=$(field "$task" 6)
  m=$(model)
  if [ -z "$(lookup "$m" task 6 "$capability")" ]; then
    echo "note: capability \"$capability\" has no open tasks: mark it shipped in docs/design/spec.md" \
      "and link its docs/impl/current/ page; until then the plan lint reports it"
  fi
  run "$LINT_AWK"
  run "$STATUS_AWK"
}

# Runs an awk program over the model; the model is built first so its errors stop the command.
run() {
  m=$(model)
  printf '%s\n' "$m" | awk "$1"
}

[ $# -ge 1 ] || usage
case $1 in
  status) [ $# -eq 1 ] || usage; run "$STATUS_AWK" ;;
  lint) [ $# -eq 1 ] || usage; run "$LINT_AWK" ;;
  start) [ $# -eq 2 ] || usage; start "$2" ;;
  close) [ $# -eq 2 ] || usage; close "$2" ;;
  *) usage ;;
esac
